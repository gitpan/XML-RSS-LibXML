# $Id: Parser.pm 17 2005-08-17 05:05:21Z daisuke $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML::Parser;
use strict;

my %VersionPrefix = (
    '2.0' => 'rss20',
    '1.0' => 'rss10',
    '0.9' => 'rss09',
);

sub new { bless {}, shift }
sub _create_parser
{
    my $self = shift;
    if (! $self->{_parser}) {
        my $p = XML::LibXML->new;
        $p->recover(1);
        $self->{_parser} = $p;
    }
    return $self->{_parser};
}

sub parse
{
    my $self = shift;
    my $rss  = shift;
    my $string = shift;

    my $p   = $self->_create_parser();
    my $dom = $p->parse_string($string);
    $self->_parse_dom($rss, $dom);
}

sub parsefile
{
    my $self = shift;
    my $rss  = shift;
    my $file = shift;

    my $p   = $self->_create_parser();
    my $dom = $p->parse_file($file);
    $self->_parse_dom($rss, $dom);
}

sub _parse_dom
{
    my $self = shift;
    my $rss  = shift;
    my $dom  = shift;

    $self->{_namespaces} = $rss->{_namespaces};

    my $xc = XML::LibXML::XPathContext->new();
    while (my($prefix, $namespace) = each %{$self->{_namespaces}}) {
        $xc->registerNs($prefix, $namespace);
    }
    $self->{_context} = $xc;

    my $version = $self->_guess_version($dom);

    $rss->{encoding} = $dom->encoding();
    $rss->{_internal}->{version} = $version;
    $rss->{channel} = $self->_parse_channel($version, $dom);
    $rss->{items} = $self->_parse_items($version, $dom);

    my $root = $dom->getDocumentElement();
    my %namespaces = (%{$rss->{_namespaces}}, 
        map { ($_->getPrefix() => $_->getNamespaceURI()) }
        grep { $_->getPrefix() }
        $root->getNamespaces);
    $rss->{_namespaces} = \%namespaces;

    delete $self->{_context};
    delete $self->{_namespaces};
}

sub _guess_version
{
    my $self = shift;
    my $dom = shift;
    my $xc  = $self->{_context};

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

my %ChannelRoot = (
    '1.0' => '/rdf:RDF/rss10:channel',
    '0.9' => '/rdf:RDF/rss09:channel',
    '2.0' => '/rss/channel'
);
sub _parse_channel
{
    my $self    = shift;
    my $version = shift;
    my $dom     = shift;

    my $xc = $self->{_context};
    my $root_xpath = $ChannelRoot{$version} || $ChannelRoot{other};

    if( my ($channel) = $xc->findnodes($root_xpath, $dom)) {
        my $h = $self->_parse_children($version, $channel);
        delete $h->{item};
        return $h;
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
    my $self    = shift;
    my $version = shift;
    my $dom     = shift;

    my @items;
    my $xc = $self->{_context};
    my $root_xpath = $ItemRoot{$version} || $ItemRoot{other};
    # grab everything by namespace 
    foreach my $item ($xc->findnodes($root_xpath, $dom)) {
        push @items, $self->_parse_children($version, $item);
    }
    return \@items;
}

sub _parse_children
{
    my $self    = shift;
    my $version = shift;
    my $node    = shift;

    my $root_xpath = $ItemRoot{$version} || $ItemRoot{other};
    my $xc = $self->{_context};
    my $vprefix = $VersionPrefix{$version};

    my %item;
    foreach my $prefix (keys %{$self->{_namespaces}}) {
        next if $prefix =~ /^rss/ && $prefix ne $vprefix;
        my %sub;

        # this separates native rss elements with those elements that
        # are explicitly tagged with a prefix.
        my $xpath = $prefix eq $vprefix ? 
            "./*" : "./*[starts-with(name(), '$prefix:')]";

        # now, for each node that we can cover, go and parse
        foreach my $node ($xc->findnodes($xpath, $node)) {
            my $text = $node->textContent();
            if ($text !~ /\S/) {
                $text = '';
            }

            # argh. it has attributes. we do our little hack...
            if ($node->hasAttributes) {
                $sub{$node->localname} = XML::RSS::LibXML::MagicElement->new(
                    content => $text,
                    attributes => [ $node->attributes ]
                );
            } else {
                $sub{$node->localname} = $text;
            }
        }

        if (keys %sub) {
            # If this is a native RSS element, we just need to assign to
            # the %item. otherwise, we need to add it to $prefix and
            # $namespace
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