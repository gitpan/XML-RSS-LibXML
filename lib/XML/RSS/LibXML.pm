# $Id: LibXML.pm 4 2005-06-14 07:13:20Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML;
use strict;
our $VERSION = '0.01';
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
    rss10   => "http://purl.org/rss/1.0/",
    rss09   => "http://my.netscape.com/rdf/simple/0.9/",
);

my %ParseContext = (
    channel => {
        link        => [ qw(link @rdf:about) ],
        creator     => [ qw(dc:creator) ],
        contributor => [ qw(dc:contributor) ],
        coverage    => [ qw(dc:coverage) ],
        title       => [ qw(title dc:title) ],
        language    => [ qw(language) ],
        copyright   => [ qw(dc:rights copyright) ],
        generator   => [ qw(admin:generatorAgent generator) ],
        identifier  => [ qw(dc:identifier) ],
    },
    item => {
        # run this only on <item> elements
        description => [ qw(description) ],
        content     => [ qw(content:encoded description) ],
        link        => [ qw(link) ],
        title       => [ qw(title dc:title) ],
        issued      => [ qw(dcterms:issued dc:date pubDate) ],
        modified    => [ qw(dcterms:modified dc:date pubDate) ],
        creator     => [ qw(dc:creator author) ]
    }
);

my %VersionPrefix = (
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
        _pctxt   => { channel => {}, item => {} },
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

    # Register parse contexts.
    while (my($context, $map) = each %ParseContext) {
        while (my($field, $xpath_list) = each %$map) {
            foreach my $xpath (@$xpath_list) {
                $self->add_parse_context(context => $context, field => $field, xpath => $xpath);
            }
        }
    }
}

sub add_module
{
    my $self = shift;
    my %args = @_;
    $self->{_context}->registerNs($args{prefix}, $args{uri});
}

sub add_parse_context
{
    my $self = shift;
    my %args = @_;

    my $context = lc($args{context});
    my $field   = lc($args{field});
    my $xpath   = $args{xpath};

    my $pctxt = $self->{_pctxt};
    $pctxt->{$context}->{$field} ||= [];
    push @{$pctxt->{$context}->{$field}}, $xpath;
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
sub channel { shift->_elem('channel') }
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
    my $xc  = XML::LibXML::XPathContext->new();
    while (my($prefix, $namespace) = each %namespaces) {
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

sub _grab_value
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
        my($v) = eval { $xc->findnodes($xpath, $node) };
        return $v->textContent() if $v;
    }
    return;
}

my %ChannelRoot = (
    '1.0'   => '/rdf:RDF/rss10:channel',
    '0.9'   => '/rdf:RDF/rss09:channel',
    'other' => '/rss/channel'
);
sub _parse_channel
{
    my $self = shift;
    my %args = @_;

    my $dom = $self->{_dom} or die "channel called before parse!";
    my %channel;
    my $version = $self->{_internal}->{version};
    my $root_xpath = $ChannelRoot{$version} || $ChannelRoot{other};
    my $xc = $self->_xpath_context();
    my($channel) = $xc->findnodes($root_xpath, $dom);

    my $value;

    my $want = $self->{_pctxt}->{channel};
    while (my($field, $xpath_list) = each %$want) {
        if (defined($value = $self->_grab_value($channel, $xc, $xpath_list))) {
            $channel{$field} = $value;
        }
    }

    return \%channel;
}

my %ItemRoot = (
    '1.0'   => '/rdf:RDF/rss10:item',
    '0.9'   => '/rdf:RDF/rss09:item',
    'other' => '/rss/channel/item'
);
sub _parse_items
{
    my $self = shift;

    my $dom = $self->{_dom} or die "channel called before parse!";

    my @items;
    my $version = $self->{_internal}->{version};
    my $root_xpath = $ItemRoot{$version} || $ItemRoot{other};
    my $xc = $self->_xpath_context;

    my $want = $self->{_pctxt}->{item};
    foreach my $item ($xc->findnodes($root_xpath, $dom)) {
        my %item;
        my $value;

        while (my($field, $xpath_list) = each %$want) {
            if (defined($value = $self->_grab_value($item, $xc, $xpath_list))) {
                $item{$field} = $value;
            }
        }
        push @items, \%item;
    }

    return wantarray ? @items : \@items;
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

  # Add custom parse contexts
  $rss->add_parse_context(
    context => $context, # 'channel', 'item'
    field   => $field_name,
    xpath   => $xpath
  );
  $rss->parse(...); # now parse with new context

=head1 DESCRIPTION

XML::RSS::LibXML uses XML::LibXML (libxml2) for parsing RSS instead of XML::RSS'
XML::Parser (expat), while trying to keep interface compatibility with XML::RSS.

XML::RSS is an extremely handy tool, but it is unfortunately not exactly the
most lean or efficient RSS parser, especially in a long-running process.
So for a long time I had been using my own version of RSS parser to get the
maximum speed and efficiency - this is the re-packaged version of that module,
such that it adheres to the XML::RSS interface.

XML::RSS::LibXML is B<NOT> 100% compatible with XML::RSS. 
For example, XML::RSS::LibXML is not capable of outputting RSS in
various formats, and namespaces aren't exactly supported the way they are
in XML::RSS (patches welcome).

Use this module when you have severe performance requirements in parsing
RSS files.

=head1 PARSED FIELDS

=head1 METHODS

=head2 new

Creates a new instance of XML::RSS::LibXML

=head2 parse($string)

Parse a string containing RSS.

=head2 parse_file($filename)

Parse an RSS file specified by $filename

=head2 as_string()

Return the string representation of the parsed RSS.

=head2 add_module(uri =E<lt> $uri, prefix =E<lt> $prefix)

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

=head2 add_parse_context(context =E<lt> $context, field =E<lt> $field, xpath =E<lt> $xpath)

Adds new parse contexts. XML::RSS::LibXML attempts to parse most of the
oft-used fields from RSS feeds, but often there are times when you want
finer grain of control.

If, for example, you want to include a custom field in within the 
E<lt>channelE<gt> element called C<foo>, you may add something like this:

  $rss->add_parse_context(
    context => 'channel',
    field   => 'foo',
    xpath   => 'foo', # XPath relative to the current context, which is
                      # 'channel'
  );
  $rss->parsefile($file);

Then after parsing, $rss will contain a structure like this:

  $rss = {
    channel => {
      foo => $value_of_foo
      # other fields
    },
    # other fields
  };

=head1 PERFORMANCE

Here's a simple benchmark using benchmark.pl in this distribution:

  daisuke@localhost XML-RSS-LibXML$ perl -Mlib=lib benchmark.pl index.rdf 
               Rate        rss rss_libxml
  rss        8.00/s         --       -97%
  rss_libxml  262/s      3172%         --

=head1 CAVEATS

No support whatsover for writing RSS. No plans to support it either.

=head1 TODO

Tests. Currently tests are simply stolen from XML::RSS. It would be nice
to have tests that do more extensive testing for correctness

=head1 SEE ALSO

L<XML::RSS|XML::RSS>, L<XML::LibXML|XML::LibXML>, L<XML::LibXML::XPathContext>

=head1 AUTHORS

Copyright 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>, Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>. All rights reserved.

Development partially funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=cut
