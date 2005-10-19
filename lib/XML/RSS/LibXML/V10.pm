#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML::V10;
use strict;
use base qw(XML::RSS::LibXML::Format);

use constant RDF_NAMESPACE => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
use constant DEFAULT_NAMESPACE => 'http://purl.org/rss/1.0/';

my %DcElements = (
    (map { ("dc:$_" => [ { module => 'dc', element => $_ } ]) }
        qw(language rights date publisher creator title subject description contributer type format identifier source relation coverage)),
);

my %SynElements = (
    (map { ("syn:$_" => [ { module => 'syn', element => $_ } ]) }
        qw(updateBase updateFrequency updatePeriod)),
);

my %RdfResourceFields = (
    'http://webns.net/mvcb/' =>  {
        'generatorAgent' => 1,
        'errorReportsTo' => 1
    },
    'http://purl.org/rss/1.0/modules/annotate/' => {
        'reference' => 1
    },
    'http://my.theinfo.org/changed/1.0/rss/' => {
        'server' => 1
    }
);

my %ChannelElements = (
    %DcElements,
    %SynElements,
    (map { ($_ => [ $_ ]) } qw(title link description)),
    'dc:language' => [ { module => 'dc', element => 'language' }, 'language' ],
    'dc:rights' => [ { module => 'dc', element => 'rights' }, 'copyright' ],
    'dc:date' => [ { module => 'dc', element => 'date' }, 'pubDate', 'lastBuildDate' ],
    'dc:publisher' => [ {module => 'dc', element => 'publisher'}, 'managingEditor' ],
    'dc:creator' => [ { module => 'dc', element => 'creator' }, 'webMaster' ],
);
my %ImageElements = (
    (map { ($_ => [$_]) } qw(title url link)),
    %DcElements,
);
my %ItemElements = (
    (map { ($_ => [$_]) } qw(title link description)),
    %DcElements
);
my %TextInputElements = (
    (map { ($_ => [$_]) } qw(title link description name)),
    %DcElements
);


sub format
{
    my $self = shift;
    my $rss  = shift;
    my $format = shift;

    $self->{_namespaces} = $rss->{_namespaces};

    my $xml  = XML::LibXML::Document->new('1.0', $rss->{encoding});
    my $node;

    my $root = $xml->createElementNS(DEFAULT_NAMESPACE, 'RDF');
    $xml->setDocumentElement($root);

    my $channel = $xml->createElement('channel');
    if ($rss->{channel} && $rss->{channel}{about}) {
        $channel->setAttribute('rdf:about', $rss->{channel}{about});
    } else {
        $channel->setAttribute('rdf:about', $rss->{channel}{link});
    }
    $root->appendChild($channel);

    my($value, $module, $element);

    $self->_populate_from_spec($xml, $channel, $rss->{channel}, \%ChannelElements);

    if (exists $rss->{channel} && $rss->{channel}{taxo}) {
        $self->_populate_taxo($xml, $channel, $rss->{channel}{taxo}, $rss->{_namespaces});
    }

    # XXX - do Ad-hoc modules
    $self->_populate_extra_modules($xml, $channel, $rss->{channel}, $rss->{_namespaces});


    if (exists $rss->{image}) {
        my $inode;

        $inode = $xml->createElement('image');
        $inode->setAttribute('rdf:resource', $rss->{image}{url});
        $channel->appendChild($inode);

        $inode = $xml->createElement('image');
        $inode->setAttribute('rdf:resource', $rss->{image}{url});
        $self->_populate_from_spec($xml, $inode, $rss->{image}, \%ImageElements);
        $self->_populate_extra_modules($xml, $inode, $rss->{image}, $rss->{_namespaces});
        $root->appendChild($inode);
    }

    if (exists $rss->{textinput}) {
        my $inode;

        $inode = $xml->createElement('textinput');
        $inode->setAttribute('rdf:resource', $rss->{textinput}{link});
        $channel->appendChild($inode);

        $inode = $xml->createElement('textinput');
        $inode->setAttribute('rdf:resource', $rss->{textinput}{link});
        $self->_populate_from_spec($xml, $inode, $rss->{textinput}, \%TextInputElements);
        $self->_populate_extra_modules($xml, $inode, $rss->{textinput}, $rss->{_namespaces});

        $root->appendChild($inode);
    }

    if ($rss->{items}) {
        my $items = $xml->createElement('items');
        my $seq   = $xml->createElement('rdf:Seq');
        foreach my $item (@{$rss->{items}}) {
            $node = $xml->createElement('rdf:li');
            $node->setAttribute('rdf:resource', $item->{about} || $item->{link});
            $seq->appendChild($node);

            my $inode = $xml->createElement('item');
            $inode->setAttribute('rdf:about', $item->{about} || $item->{link});

            $self->_populate_from_spec($xml, $inode, $item, \%ItemElements);
            $self->_populate_extra_modules($xml, $inode, $item, $rss->{_namespaces});

            $self->_populate_taxo($xml, $inode, $item->{taxo}, $self->{_namespaces});
            $root->appendChild($inode);
        }
        $items->appendChild($seq);
        $channel->appendChild($items);
    }

    $self->_populate_namespaces($rss, $root);
    $root->setNamespace(RDF_NAMESPACE, 'rdf', 1);

    $xml->toString($format, 1);
}

sub _populate_taxo
{
    my $self = shift;
    my $xml  = shift;
    my $parent = shift;
    my $taxolist = shift;
    my $namespaces = shift;

    return if !$taxolist || !scalar(@$taxolist);

    my $topic = $xml->createElement('taxo:topics');
    my $bag   = $xml->createElement('rdf:Bag');
    foreach my $taxo (@$taxolist) {
        my $node = $xml->createElement('rdf:li');
        $node->setAttribute(resource => $taxo);
        $bag->appendChild($node);
    }
    $topic->appendChild($bag);
    $parent->appendChild($topic);

    $self->{_modules}{taxo} = $namespaces->{taxo};
}

sub _populate_extra_modules
{
    my $self   = shift;
    my $xml    = shift;
    my $parent = shift;
    my $rss    = shift;
    my $namespaces = shift;

    my $node;
    while (my($prefix, $url) = each %$namespaces) {
        next if $prefix =~ /^(?:(?:dc|syn|taxo)|(?:rss\d\d))$/;
        next if ! $rss->{$prefix};
        while (my($e, $value) = each %{$rss->{$prefix}}) {
            $self->{_modules}{$prefix} ||= $url;
            $node = $xml->createElement("$prefix:$e");
            if ($RdfResourceFields{$url}{$e}) {
                $node->setAttribute('rdf:resource', $value);
            } else {
                $node->appendText($value);
            }
            $parent->appendChild($node);
        }
    }
}

1;

__END__

=head1 NAME

XML::RS::LibXML::V10 - Format XML::RSS::LibXML in RSS 1.0 Format

=head1 SYNOPSIS

  use XML::RSS::LibXML;
  use XML::RSS::LibXML::V10;

  my $rss = XML::RSS::LibXML->new();
  # populate $rss...

  my $fmt = XML::RSS::LibXML::V10->new;
  print $fmt->format($rss);

=head1 METHODS

=head2 new

=head2 format

=head1 AUTHOR

Copyright (c) 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>.
Development partially funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=cut
