# $Id: LibXML.pm 13 2005-06-21 12:31:31Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML;
use strict;
our $VERSION = '0.05';
use XML::LibXML;
use XML::LibXML::XPathContext;

my %namespaces = (
    rdf     => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    dc      => "http://purl.org/dc/elements/1.1/",
    sy      => "http://purl.org/rss/1.0/modules/syndication/",
    admin   => "http://webns.net/mvcb/",
    content => "http://purl.org/rss/1.0/modules/content/",
    cc      => "http://web.resource.org/cc/",
    taxo    => "http://purl.org/rss/1.0/modules/taxonomy/",
    rss20   => "http://backend.userland.com/rss2", # really a dummy
    rss10   => "http://purl.org/rss/1.0/",
    rss09   => "http://my.netscape.com/rdf/simple/0.9/",
);

my %VersionPrefix = (
    '2.0' => 'rss20',
    '1.0' => 'rss10',
    '0.9' => 'rss09',
);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $p = XML::LibXML->new();
    $p->recover(1);

    my $c = XML::LibXML::XPathContext->new();
    my $self = bless {
        _parser => $p,
        _context => $c,
        _namespaces => {}
    }, $class;

    $self->_init();
    return $self;
}

sub _init
{
    my $self = shift;

    # Register namespaces.
    while (my($prefix, $uri) = each %namespaces) {
        $self->add_module(prefix => $prefix, uri => $uri);
    }
}

sub add_module
{
    my $self = shift;
    my %args = @_;
    $self->{_context}->registerNs($args{prefix}, $args{uri});
    $self->{_namespaces}->{$args{prefix}} = $args{uri};
}

sub parse
{
    my $self = shift;

    my $p = $self->{_parser};
    my $dom = $p->parse_string(@_);
    $self->{_dom} = $dom;
    $self->_parse_dom;

    return $self;
}

sub parsefile
{
    my $self = shift;

    my $p = $self->{_parser};
    my $dom = $p->parse_file(@_);
    $self->{_dom} = $dom;
    $self->_parse_dom;
}

sub as_string
{
    my $self = shift;
    return $self->{_dom} ? $self->{_dom}->toString(1) : undef;
}

sub _elem { $_[0]->{$_[1]} }

sub channel
{
    my $self = shift;
    return $_[0] ? $self->_elem('channel')->{$_[0]} : $self->_elem('channel');
}

sub items   { shift->_elem('items')   }

sub _parse_dom
{
    my $self = shift;

    $self->{_internal}->{version} = $self->_guess_version();
    $self->{channel} = $self->_parse_channel;
    $self->{items} = $self->_parse_items;
}

sub _xpath_context
{
    my $self = shift;
    my $xc  = XML::LibXML::XPathContext->new();
    while (my($prefix, $namespace) = each %{$self->{_namespaces}}) {
        $xc->registerNs($prefix, $namespace);
    }
    return $xc;
}

sub _guess_version
{
    my $self = shift;
    $self->{_dom} or die;

    my $dom = $self->{_dom};
    my $xc  = $self->_xpath_context();

    # Test starting from the most likely candidate
    if ($xc->findnodes('/rdf:RDF', $dom)) {
        # 1.0 or 0.9
        if ($xc->findnodes('/rdf:RDF/rss10:channel', $dom)) {
            return '1.0';
        } else {
            return '0.9';
        }
    } elsif ($xc->findnodes('/rss', $dom)) {
        # 0.91 or 2.0 -ish
        return $xc->findvalue('/rss/@version', $dom);
    }
    return 'UNKNOWN';
}

sub grab_data
{
    my($self, $node, $xc, $candidates) = @_;
    return unless $candidates;

    my $xpath;
    my $version = $self->{_internal}->{version};
    foreach my $xp (@$candidates) {
        if ($xp !~ /^[^:]+:/ && $VersionPrefix{$version}) {
            $xpath = $VersionPrefix{$version} . ":$xp";
        } else {
            $xpath = $xp;
        }
        if (my($v) = eval { $xc->findnodes($xpath, $node) }) {
            my %data;
            if (my $prefix = $v->prefix) {
                $data{prefix} = $prefix;
                $data{name}   = $v->localname;
            }
            $data{data} = $v->textContent();
            return \%data;
        }
    }
    return;
}

my %ChannelRoot = (
    '1.0' => '/rdf:RDF/rss10:channel',
    '0.9' => '/rdf:RDF/rss09:channel',
    '2.0' => '/rss/channel'
);
sub _parse_channel
{
    my $self = shift;
    my %args = @_;

    my $dom = $self->{_dom} or die "channel called before parse!";
    my $version = $self->{_internal}->{version};
    my $xc = $self->_xpath_context;
    my $root_xpath = $ChannelRoot{$version} || $ChannelRoot{other};

    if( my ($channel) = $xc->findnodes($root_xpath, $dom)) {
        return $self->_parse_children($channel);
    }
    return undef;
}

my %ItemRoot = (
    '1.0'   => '/rdf:RDF/rss10:item',
    '0.9'   => '/rdf:RDF/rss09:item',
    '2.0' => '/rss/channel/item'
);

sub _parse_items
{
    my $self = shift;

    my $dom = $self->{_dom} or die "channel called before parse!";

    my @items;
    my $version = $self->{_internal}->{version};
    my $xc = $self->_xpath_context;
    my $root_xpath = $ItemRoot{$version} || $ItemRoot{other};
    # grab everything by namespace 
    foreach my $item ($xc->findnodes($root_xpath, $dom)) {
        push @items, $self->_parse_children($item);
    }
    return wantarray ? @items : \@items;
}

sub _parse_children
{
    my $self = shift;
    my $node = shift;
    my $version = $self->{_internal}->{version};
    my $root_xpath = $ItemRoot{$version} || $ItemRoot{other};
    my $xc = $self->_xpath_context;
    my $vprefix = $VersionPrefix{$version};

    my %item;
    foreach my $prefix (keys %{$self->{_namespaces}}) {
        next if $prefix =~ /^rss/ && $prefix ne $vprefix;
        my %sub;
        my $xpath = $prefix eq $vprefix ? 
            "./*" : "./*[starts-with(name(), '$prefix:')]";
        foreach my $node ($xc->findnodes($xpath, $node)) {
            $sub{$node->localname} = $node->textContent();
        }
        if (keys %sub) {
            if ($vprefix eq $prefix) {
                while (my ($key, $value) = each %sub) {
                    $item{$key} = $value;
                }
            } else {
                $item{$prefix} = \%sub;
		$item{$self->{_namespaces}->{$prefix}} = \%sub;
            }
        }
    }
    return \%item;
}
1;

__END__

=head1 NAME

XML::RSS::LibXML - XML::RSS with XML::LibXML (parse-only)

=head1 SYNOPSIS

  use XML::RSS::LibXML;
  my $rss = XML::RSS::LibXML->new;
  $rss->parsefile($file);

  print "channel: $rss->{channel}->{title}\n";
  foreach my $item (@{ $rss->{items} }) {
     print "  item: $item->{title} ($item->{link})\n";
  }

  # Add custom modules
  $rss->add_module(uri => $uri, prefix => $prefix);

=head1 DESCRIPTION

XML::RSS::LibXML uses XML::LibXML (libxml2) for parsing RSS instead of XML::RSS'
XML::Parser (expat), while trying to keep interface compatibility with XML::RSS.

XML::RSS is an extremely handy tool, but it is unfortunately not exactly the
most lean or efficient RSS parser, especially in a long-running process.
So for a long time I had been using my own version of RSS parser to get the
maximum speed and efficiency - this is the re-packaged version of that module,
such that it adheres to the XML::RSS interface.

Use this module when you have severe performance requirements in parsing
RSS files.

=head1 COMPATIBILITY

There seems to be a bit of confusion as to how compatible XML::RSS::LibXML 
is with XML::RSS: XML::RSS::LibXML is B<NOT> 100% compatible with XML::RSS. 
For example, XML::RSS::LibXML is not capable of outputting RSS in
various formats. It also doesn't do complete parsing of the XML document
because of the way we deal with XPath and libxml's DOM (see CAVEATS below)

On top of that, I originally wrote XML::RSS::LibXML as sort of a fast 
replacement for XML::RAI, which looked cool in terms of abstracting the 
various modules.  And therefore versions prior to 0.02 worked more like 
XML::RAI rather than XML::RSS. That was a mistake in hind sight, so it has
been addressed.

From now on XML::RSS::LibXML will try to match XML::RSS's functionality as
much as possible in terms of parsing RSS feeds. Please send in patches and
any tests that may be useful!

=head1 PARSED FIELDS

=head1 METHODS

=head2 new

Creates a new instance of XML::RSS::LibXML

=head2 parse($string)

Parse a string containing RSS.

=head2 parsefile($filename)

Parse an RSS file specified by $filename

=head2 as_string()

Return the string representation of the parsed RSS.

=head2 add_module(uri =E<gt> $uri, prefix =E<gt> $prefix)

Adds a new module. You should do this before parsing the RSS.
XML::RSS::LibXML understands a few modules by default:

    rdf     => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    dc      => "http://purl.org/dc/elements/1.1/",
    sy      => "http://purl.org/rss/1.0/modules/syndication/",
    admin   => "http://webns.net/mvcb/",
    content => "http://purl.org/rss/1.0/modules/content/",
    cc      => "http://web.resource.org/cc/",
    taxo    => "http://purl.org/rss/1.0/modules/taxonomy/",

So you do not need to add these explicitly.

=head1 PERFORMANCE

Here's a simple benchmark using benchmark.pl in this distribution:

  daisuke@localhost XML-RSS-LibXML$ perl -Mlib=lib benchmark.pl index.rdf 
               Rate        rss rss_libxml
  rss        8.00/s         --       -97%
  rss_libxml  262/s      3172%         --

=head1 CAVEATS

No support whatsover for writing RSS. No plans to support it either.

Only first level data under E<lt>channelE<gt> and E<lt>itemE<gt> tags are
examined. So if you have complex data, this module will not pick it up.
For most of the cases, this will suffice, though.

=head1 TODO

Tests. Currently tests are simply stolen from XML::RSS. It would be nice
to have tests that do more extensive testing for correctness

=head1 SEE ALSO

L<XML::RSS|XML::RSS>, L<XML::LibXML|XML::LibXML>, L<XML::LibXML::XPathContext>

=head1 AUTHORS

Copyright 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>, Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>. All rights reserved.

Development partially funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=cut
