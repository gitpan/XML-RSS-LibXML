# $Id: V20.pm 25 2006-03-04 23:24:56Z daisuke $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML::V20;
use strict;
use base qw(XML::RSS::LibXML::Format);

my %DcElements = (
    (map { ("dc:$_" => [ { module => 'dc', element => $_ } ]) }
        qw(language rights date publisher creator title subject description contributer type format identifier source relation coverage)),
);

my %SynElements = (
    (map { ("syn:$_" => [ { module => 'syn', element => $_ } ]) }
        qw(updateBase updateFrequency updatePeriod)),
);

my %ChannelElements = (
    %DcElements,
    %SynElements,
    (map { ($_ => [ $_ ]) } qw(title link description)),
    language => [ { module => 'dc', element => 'language' }, 'language' ],
    copyright => [ { module => 'dc', element => 'rights' }, 'copyright' ],
    pubDate   => [ 'pubDate', { module => 'dc', element => 'date' } ],
    lastBuildDate => [ { module => 'dc', element => 'date' }, 'lastBuildDate' ],
    docs => [ 'docs' ],
    managingEditor => [ { module => 'dc', element => 'publisher' }, 'managingEditor' ],
    webMaster => [ { module => 'dc', element => 'creator' }, 'webMaster' ],
    category => [ { module => 'dc', element => 'category' }, 'category' ],
    generator => [ { module => 'dc', element => 'generator' }, 'generator' ],
    ttl => [ { module => 'dc', element => 'ttl' }, 'ttl' ],
);

my @ImageElements = qw(title url link width height description);
# my @ItemElements  = qw(title link description author category comments pubDate);
my %ItemElements = (
    %DcElements,
    map { ($_ => [$_]) }
        qw(title link description author category comments pubDate)
);
my @TextInputElements = qw(title description name link);

sub format
{
    my $self = shift;
    my $rss  = shift;
    my $format = shift;

    my $xml  = XML::LibXML::Document->new('1.0', $rss->{encoding});
    my $node;

    my $root = $xml->createElement('rss');
    $root->setAttribute(version => '2.0');
    $self->_populate_namespaces($rss, $root);
    $xml->setDocumentElement($root);

    my $channel = $xml->createElement('channel');
    $root->appendChild($channel);

    my($value, $module, $element);

    $self->_populate_from_spec($xml, $channel, $rss->{channel}, \%ChannelElements);

    if (exists $rss->{image}) {
        my $image = $xml->createElement('image');
        foreach my $e (@ImageElements) {
            $node = $xml->createElement($e);
            $node->appendText($rss->{image}{$e});
            $image->addChild($node);
        }
        $channel->addChild($image);
    }

    foreach my $item (@{$rss->{items}}) {
        my $inode = $xml->createElement('item');

        $self->_populate_from_spec($xml, $inode, $item, \%ItemElements);

        # Be compatible with XML::RSS if the node isn't MagicElement
        # for enclosure, source, and guid

        if (exists $item->{enclosure}) {
            my $e = $item->{enclosure};
            $node = $xml->createElement('enclosure');
            if (eval { $e->isa('XML::RSS::LibXML::MagicElement') }) {
                $self->_populate_node($node, $inode, $e);
            } else {
                while (my($key, $value) = each %$e) {
                    $node->setAttribute($key, $value);
                }
                $inode->appendChild($node);
            }
        }

        if (exists $item->{source} && (my $source = $item->{source})) {
            $node = $xml->createElement('source');
            if (eval { $source->isa('XML::RSS::LibXML::MagicElement') }) {
                $self->_populate_node($node, $inode, $source);
            } elsif ($item->{source} && $item->{sourceUrl}) {
                $node->setAttribute(url => $item->{sourceUrl});
                $node->appendText($source);
                $inode->appendChild($node);
            }
        }

        if (my $guid = $item->{guid}) {
            $node = $xml->createElement('guid');
            if (eval { $guid->isa('XML::RSS::LibXML::MagicElement') }) {
                $self->_populate_node($node, $inode, $guid);
            } elsif ($item->{permaLink}) {
                $node->setAttribute(isPermaLink => 'true');
                $node->appendText($item->{permaLink});
                $inode->appendChild($node);
            } elsif ($item->{guid}) {
                $node->setAttribute(isPermaLink => 'false');
                $node->appendText($item->{guid});
                $inode->appendChild($node);
            }
        }

        $channel->appendChild($inode);
    }

    if (exists $rss->{textinput} && $rss->{textinput}{link}) {
        my $textinput = $xml->createElement('textInput');
        foreach my $e (@TextInputElements) {
            $node = $xml->createElement($e);
            $node->appendText($rss->{textinput}{$e});
            $textinput->appendChild($node);
        }
        $channel->appendChild($textinput);
    }

    if (exists $rss->{skipHours} && $rss->{skipHours}{hour}) {
        my $skip = $xml->createElement('skipHours');
        $node = $xml->createElement('hour');
        $node->appendText($rss->{skipHours}{hour});
        $skip->appendChild($node);
        $channel->appendChild($skip);
    }

    if (exists $rss->{skipDays} && $rss->{skipDays}{day}) {
        my $skip = $xml->createElement('skipDays');
        $node = $xml->createElement('day');
        $node->appendText($rss->{skipDays}{day});
        $skip->appendChild($node);
        $channel->appendChild($skip);
    }
    $xml->toString($format, 1);
}

1;

__END__

=head1 NAME

XML::RSS::LibXML::V20 - Format XML::RSS::LibXML in RSS 2.0 Format

=head1 SYNOPSIS

  use XML::RSS::LibXML;
  use XML::RSS::LibXML::V20;

  my $rss = XML::RSS::LibXML->new();
  # populate $rss...

  my $fmt = XML::RSS::LibXML::V20->new;
  print $fmt->format($rss);

=head1 METHODS

=head2 new

=head2 format

=head1 AUTHOR

Copyright (c) 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>.
Development partially funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=cut

