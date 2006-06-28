# $Id: /mirror/XML-RSS-LibXML/lib/XML/RSS/LibXML/V09.pm 1104 2005-12-28T09:18:23.970746Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML::V09;
use strict;
use base qw(XML::RSS::LibXML::Format);
use constant RDF_NAMESPACE => "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
use constant DEFAULT_NAMESPACE => "http://my.netscape.com/rdf/simple/0.9/";

my @ChannelElements = qw(title link description);
my @ImageElements = qw(title link description url);
my @ItemElements = qw(title link);
my @TextInputElements = qw(title description name link);
sub format
{
    my $self = shift;
    my $rss = shift;
    my $format = shift;

    my $xml  = XML::LibXML::Document->new('1.0', $rss->{encoding});
    my $node;

    my $root = $xml->createElementNS(DEFAULT_NAMESPACE, 'RDF');
    $xml->setDocumentElement($root);
    $root->setNamespace(RDF_NAMESPACE, 'rdf', 1);

    my $channel = $xml->createElement('channel');
    $root->appendChild($channel);
 
    foreach my $p (@ChannelElements) {
        $node = $xml->createElement($p);
        $node->appendText($rss->{channel}{$p});
        $channel->appendChild($node);
    }

    if ($rss->{image}) {
        my $image = $xml->createElement('image');
        foreach my $e (@ImageElements) {
            next if !exists $rss->{image} || !exists $rss->{image}{$e};
            $node = $xml->createElement($e);
            $node->appendText($rss->{image}{$e});
            $image->addChild($node);
        }
        $root->addChild($image);
    }

    foreach my $item (@{$rss->{items}}) {
        my $inode = $xml->createElement('item');
        foreach my $e (@ItemElements) {
            $node = $xml->createElement($e);
            $node->appendText($item->{$e});
            $inode->addChild($node);
        }
        $root->addChild($inode);
    }

    if ($rss->{textinput} && $rss->{textinput}{link}) {
        my $textinput = $xml->createElement('textInput');
        foreach my $e (@TextInputElements) {
            $node = $xml->createElement($e);
            $node->appendText($rss->{textinput}{$e});
            $textinput->appendChild($node);
        }
        $root->appendChild($textinput);
    }

    $xml->toString($format, 1);
}

1;

__END__

=head1 NAME

XML::RSS::LibXML::V09 - Format XML::RSS::LibXML in RSS 0.9 Format

=head1 SYNOPSIS

  use XML::RSS::LibXML;
  use XML::RSS::LibXML::V09;

  my $rss = XML::RSS::LibXML->new();
  # populate $rss...

  my $fmt = XML::RSS::LibXML::V09->new;
  print $fmt->format($rss);

=head1 METHODS

=head2 new

=head2 format

=head1 AUTHOR

Copyright (c) 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>.
Development partially funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=cut
