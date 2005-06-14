# $Id: LibXML.pm 3 2005-06-14 04:52:03Z daisuke $
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

my %xpath_catalog = (
    channel => {
        link        => [ qw(link @rdf:about) ],
        creator     => [ qw(dc:creator) ],
        title       => [ qw(title dc:title) ],
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

my %version_prefix = (
    '1.0' => 'rss10',
    '0.9' => 'rss09',
);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $p = XML::LibXML->new();
    $p->recover(1);
    bless {
        _parser => $p,
    }, $class;
}

sub parse
{
    my $self = shift;

    my $p = $self->{_parser};
    my $dom = $p->parse_string(@_);
    $self->{_dom} = $dom;
    $self->_analyze();

    return $self;
}

sub parsefile
{
    my $self = shift;

    my $p = $self->{_parser};
    my $dom = $p->parse_file(@_);
    $self->{_dom} = $dom;
}

sub _analyze
{
    my $self = shift;

    $self->{_internal}->{version} = $self->_guess_version();
    $self->{channel} = $self->channel;
    $self->{items} = $self->items;
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
        if ($xp !~ /^[^:]+:/ && $version_prefix{$version}) {
            $xpath = $version_prefix{$version} . ":$xp";
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
sub channel
{
    my $self = shift;
    my %args = @_;

    my $dom = $self->{_dom} or die "channel called before parse!";
    my %channel;
    my $version = $self->{_internal}->{version};
    my $root_xpath = $ChannelRoot{$version} || $ChannelRoot{other};
    my $xc = $self->_xpath_context();
    my($channel) = $xc->findnodes($root_xpath, $dom);
    
    foreach my $want qw(title link description) {
        $channel{$want} = $self->_grab_value($channel, $xc, $xpath_catalog{channel}{$want});
    }

    return \%channel;
}

my %ItemRoot = (
    '1.0'   => '/rdf:RDF/rss10:item',
    '0.9'   => '/rdf:RDF/rss09:item',
    'other' => '/rss/channel/item'
);
sub items
{
    my $self = shift;

    my $dom = $self->{_dom} or die "channel called before parse!";

    my @items;
    my $version = $self->{_internal}->{version};
    my $root_xpath = $ItemRoot{$version} || $ItemRoot{other};
    my $xc = $self->_xpath_context;
    foreach my $item ($xc->findnodes($root_xpath, $dom)) {
        my %item;
        my $value;
        foreach my $want qw(link title description content issued modified creator) {
            if (defined($value = $self->_grab_value($item, $xc, $xpath_catalog{item}{$want}))) {
                $item{$want} = $value;
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

=head1 DESCRIPTION

XML::RSS is an extremely handy tool, but it is unfortunately not exactly the
most lean or efficient RSS parser, especially in a long-running process. So
for a long time I had been using my own version of RSS parser to get the maximum
speed and efficiency - this is the re-packaged version of such module, such that
it adheres to the XML::RSS interface.

It uses XML::LibXML as the underlying XML parser, and is therefore much much
faster than XML::RSS

YMMV, but in reality, I do not parse RSS files this way -- because where 
performance matters, it is important to *NOT* store unnecessary data in memory.
So do note that while this module may achieve what XML::RSS does faster, but
it's not the solution. 

=head1 METHODS

=head2 new

Creates a new instance of XML::RSS::LibXML

=head2 parse($string)

Parse a string containing RSS.

=head2 parse_file($filename)

Parse an RSS file specified by $filename

=head1 PERFORMANCE

Here's a simple benchmark using benchmark.pl in this distribution:

  daisuke@localhost XML-RSS-LibXML$ perl -Mlib=lib benchmark.pl index.rdf 
               Rate        rss rss_libxml
  rss        8.00/s         --       -97%
  rss_libxml  262/s      3172%         --

=head1 CAVEATS

No support whatsover for writing RSS. No plans to support it either.

=head1 TODO

Tests. Currently tests are simply stolen from XML::RSS. 

=head1 SEE ALSO

L<XML::RSS|XML::RSS>, L<XML::LibXML|XML::LibXML>, L<XML::LibXML::XPathContext>

=head1 AUTHOR

Copyright 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>. All rights reserved.
Development funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=cut
