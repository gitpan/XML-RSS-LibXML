# $Id: V09.pm 18 2005-08-17 10:20:53Z daisuke $
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
