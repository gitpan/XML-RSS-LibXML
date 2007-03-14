# $Id: V0_9.pm 33 2007-03-14 03:06:58Z daisuke $
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package XML::RSS::LibXML::V0_9;
use strict;
use base qw(XML::RSS::LibXML::ImplBase);
use Carp qw(croak);
use XML::RSS::LibXML::Namespaces qw(NS_RSS09 NS_RDF);

sub definition
{
    return {
        channel => {
            title       => '',
            description => '',
            link        => '',
        },
        image => {
            title => undef,
            url   => undef,
            link  => undef,
        },
        textinput => {
            title       => undef,
            description => undef,
            name        => undef,
            link        => undef,
        },
    },
}

sub accessor_definition
{
    return +{
        channel => {
            "title"       => [1, 40],
            "description" => [1, 500],
            "link"        => [1, 500]
        },
        image => {
            "title" => [1, 40],
            "url"   => [1, 500],
            "link"  => [1, 500]
        },
        item => {
            "title" => [1, 100],
            "link"  => [1, 500]
        },
        textinput => {
            "title"       => [1, 40],
            "description" => [1, 100],
            "name"        => [1, 500],
            "link"        => [1, 500]
        }
    }
}

sub parse_dom
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;

    $c->reset;
    $c->version(0.9);
    $self->parse_namespaces($c, $dom);
    $c->internal('prefix', 'rss09');
    # Check if we have non-default RSS namespace
    my $namespaces = $c->namespaces;
    while (my($prefix, $uri) = each %$namespaces) {
        if ($uri eq NS_RSS09 && $prefix ne '#default') {
            $c->internal('prefix', $prefix);
            last;
        }
    }

    $dom->getDocumentElement()->setNamespace(NS_RSS09, $c->internal('prefix'), 0);
    $self->parse_channel($c, $dom);
    $self->parse_items($c, $dom);
}

sub parse_namespaces
{
    my ($self, $c, $dom) = @_;

    $self->SUPER::parse_namespaces($c, $dom);

    my $namespaces = $c->namespaces;
    while (my($prefix, $uri) = each %$namespaces) {
        if ($uri eq NS_RSS09) {
            
        }
    }
}

sub parse_channel
{
    my ($self, $c, $dom) = @_;

    my $xc = $c->create_xpath_context($c->{namespaces});

    my ($root) = $xc->findnodes('/rdf:RDF/rss09:channel', $dom);
    my %h = $self->parse_children($c, $root);
    $c->channel(%h);
}

sub parse_items
{
    my $self    = shift;
    my $c       = shift;
    my $dom     = shift;

    my @items;

    my $version = $c->version;
    my $xc      = $c->create_xpath_context($c->{namespaces});
    my $xpath   = '/rdf:RDF/rss09:item';
    foreach my $item ($xc->findnodes($xpath, $dom)) {
        my $i = $self->parse_children($c, $item);
        $self->add_item($c, $i);
    }
}

sub validate_item
{
    my $self = shift;
    my $c    = shift;
    my $h    = shift;

    # make sure we have a title and link
    croak "title and link elements are required"
      unless ($h->{title} && $h->{'link'});

    # check string lengths
    croak "title cannot exceed 100 characters in length"
      if (length($h->{title}) > 100);
    croak "link cannot exceed 500 characters in length"
      if (length($h->{'link'}) > 500);
    croak "description cannot exceed 500 characters in length"
      if (exists($h->{description})
        && length($h->{description}) > 500);

    # make sure there aren't already 15 items
    croak "total items cannot exceed 15 " if (@{$c->items} >= 15);
}

sub create_rootelement
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;

    my $e = $dom->createElementNS(NS_RSS09, 'RDF');
    $dom->setDocumentElement($e);
    $e->setNamespace(NS_RDF, 'rdf', 1);
    $c->add_module(prefix => 'rdf', uri => NS_RDF);
}

sub create_channel
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;
    my $root = $dom->getDocumentElement();

    my $channel = $dom->createElement('channel');
    $root->appendChild($channel);

    my $node;
    foreach my $p qw(title link description) {
        my $text = $c->{channel}{$p};
        next unless defined $text;
        $node = $dom->createElement($p);
        $node->appendText($c->{channel}{$p});
        $channel->appendChild($node);
    }
}

sub create_items
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;
    my $root = $dom->getDocumentElement();

    foreach my $i ($c->items) {
        my $item = $self->create_item($c, $dom, $i);
        $root->appendChild($item);
    }
}

sub create_item
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;
    my $i    = shift;

    my $item = $dom->createElement('item');
    my $node;
    foreach my $e qw(title link) {
        $node = $dom->createElement($e);
        $node->appendText($i->{$e});
        $item->addChild($node);
    }
    return $item;
}

1;