# $Id: LibXML.pm 17 2005-08-17 05:05:21Z daisuke $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML;
use strict;
use vars qw($VERSION);
$VERSION = '0.08';
use XML::LibXML;
use XML::LibXML::XPathContext;
use XML::RSS::LibXML::MagicElement;

my $LoadedParser = 0;
my $LoadedGenerator = 0;
my %namespaces = (
    rdf     => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    dc      => "http://purl.org/dc/elements/1.1/",
    syn     => "http://purl.org/rss/1.0/modules/syndication/",
    admin   => "http://webns.net/mvcb/",
    content => "http://purl.org/rss/1.0/modules/content/",
    cc      => "http://web.resource.org/cc/",
    taxo    => "http://purl.org/rss/1.0/modules/taxonomy/",
    rss20   => "http://backend.userland.com/rss2", # really a dummy
    rss10   => "http://purl.org/rss/1.0/",
    rss09   => "http://my.netscape.com/rdf/simple/0.9/",
);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $self = bless {
        _namespaces => {}
    }, $class;

    if ($args{version}) {
        $self->{output} = $args{version};
    }

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

    $self->{_namespaces}->{$args{prefix}} = $args{uri};
}

sub _create_parser
{
    my $self = shift;

    if (!$LoadedParser) {
        require XML::RSS::LibXML::Parser;
        $LoadedParser++;
    }

    if (! $self->{_parser}) {
        $self->{_parser} = XML::RSS::LibXML::Parser->new;
    }

    return $self->{_parser};
}

sub parse
{
    my $self = shift;
    my $p = $self->_create_parser();
    $p->parse($self, @_);
    return $self;
}

sub parsefile
{
    my $self = shift;
    my $p = $self->_create_parser();
    $p->parsefile($self, @_);
    return $self;
}

sub save
{
    my $self = shift;
    my $file = shift;

    open(OUT, ">$file") or Carp::croak("Cannot open file $file for write: $!");
    print OUT $self->as_string;
    close(OUT);
}

sub _elem { $_[0]->{$_[1]} }

sub _create_generator
{
    my $self = shift;

    if (!$LoadedGenerator) {
        require XML::RSS::LibXML::Generator;
        $LoadedGenerator++;
    }

    if (! $self->{_generator}) {
        $self->{_generator} = XML::RSS::LibXML::Generator->new;
    }
    return $self->{_generator};
}

sub channel
{
    my $self = shift;
    if (@_) {
        my $g = $self->_create_generator();
        $g->channel($self, @_);
    }
    return $self->_elem('channel');
}

sub image
{
    my $self = shift;
    if (@_) {
        my $g = $self->_create_generator();
        $g->image($self, @_);
    }
    return $self->_elem('image');
}

sub textinput
{
    my $self = shift;
    if (@_) {
        my $g = $self->_create_generator();
        $g->textinput($self, @_);
    }
    return $self->_elem('textinput');
}

sub add_item
{
    my $self = shift;

    if (@_) {
        my $g = $self->_create_generator();
        $g->add_item($self, @_);
    }
}

sub items { shift->_elem('items') }

my %VersionFormatter = (
    '0.9' => 'XML::RSS::LibXML::V09',
    '1.0' => 'XML::RSS::LibXML::V10',
    '2.0' => 'XML::RSS::LibXML::V20'
);
my %LoadedFormatter;
sub as_string
{
    my $self = shift;
    my $format = @_ ? shift : 1;

    my $fmt_class = $self->{fmt_class};
    my $version = $self->{output} || $self->{_internal}{version} || '1.0';
    if (!$fmt_class) {
        $fmt_class = $VersionFormatter{$version};
    }

    die "No formatter found for RSS version $version" if ! $fmt_class;

    if (! $LoadedFormatter{$fmt_class}) {
        eval "require $fmt_class"; die if $@;
        $LoadedFormatter{$fmt_class}++;
    }
    
    my $fmt = $fmt_class->new;

    $self->{encoding} ||= 'UTF-8';
    $fmt->format($self, $format);
}

1;

__END__

=head1 NAME

XML::RSS::LibXML - XML::RSS with XML::LibXML

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

  # See docs for XML::RSS for these
  $rss->channel(...);
  $rss->add_item(...);
  $rss->image(...);
  $rss->textinput(...);
  $rss->save(...);

  $rss->as_string($format);

=head1 DESCRIPTION

XML::RSS::LibXML uses XML::LibXML (libxml2) for parsing RSS instead of XML::RSS'
XML::Parser (expat), while trying to keep interface compatibility with XML::RSS.

XML::RSS is an extremely handy tool, but it is unfortunately not exactly the
most lean or efficient RSS parser, especially in a long-running process.
So for a long time I had been using my own version of RSS parser to get the
maximum speed and efficiency - this is the re-packaged version of that module,
such that it adheres to the XML::RSS interface.

Use this module when you have severe performance requirements working with
RSS files.

=head1 COMPATIBILITY

There seems to be a bit of confusion as to how compatible XML::RSS::LibXML 
is with XML::RSS: XML::RSS::LibXML is B<NOT> 100% compatible with XML::RSS. 
For instance XML::RS::LibXML does not do a complete parsing of the XML document
because of the way we deal with XPath and libxml's DOM (see CAVEATS below)

On top of that, I originally wrote XML::RSS::LibXML as sort of a fast 
replacement for XML::RAI, which looked cool in terms of abstracting the 
various modules.  And therefore versions prior to 0.02 worked more like 
XML::RAI rather than XML::RSS. That was a mistake in hind sight, so it has
been addressed (Since XML::RSS::LibXML version 0.08, it even supports
writing RSS :)

From now on XML::RSS::LibXML will try to match XML::RSS's functionality as
much as possible in terms of parsing RSS feeds. Please send in patches and
any tests that may be useful!

=head1 PARSED STRUCTURE

Once parsed the resulting data structure resembles that of XML::RSS. However,
as one addition/improvement, XML::RSS::LibXML uses a technique to allow users
to access complex data structures that XML::RSS doesn't support as of this
writing.

For example, suppose you have a tag like the following:

  <rss version="2.0">
  ...
    <channel>
      <tag attr1="val1" attr2="val3">foo bar baz</tag>
    </channel>
  </rss>

All of the fields in this construct can be accessed like so:

  $rss->channel->{tag}        # "foo bar baz"
  $rss->channel->{tag}{attr1} # "val1"
  $rss->channel->{tag}{attr2} # "val2"

See L<XML::RSS::LibXML::MagicElement|XML::RSS::LibXML::MagicElement> for details.

=head1 METHODS

=head2 new(%args)

Creates a new instance of XML::RSS::LibXML. You may specify a version in the
constructor args to control which output format as_string() will use.

  XML::RSS::LibXML->new(version => '1.0');

=head2 parse($string)

Parse a string containing RSS.

=head2 parsefile($filename)

Parse an RSS file specified by $filename

=head2 channel(%args)

=head2 add_item(%args)

=head2 image(%args)

=head2 textinput(%args)

These methods are used to generate RSS. See the documentation for XML::RSS
for details. Currently RSS version 0.9, 1.0, and 2.0 are supported.

=head2 as_string($format)

Return the string representation of the parsed RSS. If $format is true, this
flag is passed to the underlying XML::LibXML object's toString() method.

By default, $format is true.

=head2 add_module(uri =E<gt> $uri, prefix =E<gt> $prefix)

Adds a new module. You should do this before parsing the RSS.
XML::RSS::LibXML understands a few modules by default:

    rdf     => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    dc      => "http://purl.org/dc/elements/1.1/",
    syn     => "http://purl.org/rss/1.0/modules/syndication/",
    admin   => "http://webns.net/mvcb/",
    content => "http://purl.org/rss/1.0/modules/content/",
    cc      => "http://web.resource.org/cc/",
    taxo    => "http://purl.org/rss/1.0/modules/taxonomy/",

So you do not need to add these explicitly.

=head1 PERFORMANCE

Here's a simple benchmark using benchmark.pl in this distribution:

  daisuke@localhost XML-RSS-LibXML$ perl -Mlib=lib benchmark.pl index.rdf 
               Rate        rss rss_libxml
  rss        4.40/s         --       -86%
  rss_libxml 32.2/s       633%         --

=head1 CAVEATS

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
