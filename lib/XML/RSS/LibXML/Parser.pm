# $Id: /mirror/XML-RSS-LibXML/lib/XML/RSS/LibXML/Parser.pm 1110 2006-05-31T11:10:14.016366Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML::Parser;
use strict;

my %VersionPrefix = (
    '2.0' => 'rss20',
    '1.0' => 'rss10',
    '0.9' => 'rss09',
    '0.91' => 'rss09'
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

sub _create_context
{
    my $self = shift;
    my $xc = XML::LibXML::XPathContext->new();
    while (my($prefix, $namespace) = each %{$self->{_namespaces}}) {
        $xc->registerNs($prefix, $namespace);
    }
    return $xc;
}

my %Root = (
    '1.0' => '/rdf:RDF',
    '0.9' => '/rdf:RDF',
    '2.0' => '/rss',
    'other' => '/rss'
);
    
sub _parse_dom
{
    my $self = shift;
    my $rss  = shift;
    my $dom  = shift;

    my $root = $dom->getDocumentElement();
    $self->{_namespaces} = {
        %{$rss->{_namespaces}}, 
        map { ($_->getPrefix() => $_->getNamespaceURI()) }
            grep { $_->getPrefix() }
            $root->getNamespaces
    };
    $self->{_context} = $self->_create_context;

    my $version = $self->_guess_version($dom);

    $rss->{encoding} = $dom->encoding();
    $rss->{_internal}{version} = $version;
    $rss->{version} = $version;
    $rss->{output} = $version;
    $rss->{channel} = $self->_parse_channel($version, $dom);

    $rss->{items} = $self->_parse_items($version, $dom);

    my $root_xpath = $Root{$version} || $Root{other};
    foreach my $node ($self->{_context}->findnodes($root_xpath . '/*[name() != "channel" and name() != "item"]', $dom)) {
        my $h = $self->_parse_children($version, $node);
        if (my $prefix = $node->getPrefix()) {
            $rss->{$prefix}{$node->localname} = $h;
        } else {
            $rss->{$node->localname} = $h;
        }
    }

    if ($version eq '2.0') {
        $rss->{image} = $rss->{channel}{image}
            if exists $rss->{channel} && exists $rss->{channel}{image};
        $rss->{textinput} = $rss->{channel}{textInput}
            if exists $rss->{channel}{textInput};
    }

    $rss->{_namespaces} = $self->{_namespaces};

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
    '2.0' => '/rss/channel',
    'other' => '/rss/channel'
);
sub _parse_channel
{
    my $self    = shift;
    my $version = shift;
    my $dom     = shift;

    my $xc = $self->{_context};
    my $root_xpath = $ChannelRoot{$version} || $ChannelRoot{other};

    my $h;
    if( my ($channel) = $xc->findnodes($root_xpath, $dom)) {
        $h = $self->_parse_children($version, $channel);
        delete $h->{item};
        delete $h->{taxo};

        $self->_parse_taxo($h, $channel);
    }

    return $h;
}

sub _parse_taxo
{
    my $self = shift;
    my $h    = shift;
    my $xml  = shift;

    my $xc = $self->{_context};
    my @nodes = $xc->findnodes('taxo:topics/rdf:Bag/rdf:li', $xml);

    return if !@nodes;

    $h->{taxo} ||= [];
    foreach my $p (@nodes) {
        push @{$h->{taxo}}, $p->findvalue('@resource');
    }
    $h->{$self->{_namespaces}{taxo}} = $h->{taxo};
}

my %ItemRoot = (
    '1.0' => '/rdf:RDF/rss10:item',
    '0.9' => '/rdf:RDF/rss09:item',
    '2.0' => '/rss/channel/item',
    'other' => '/rss/channel/item'
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
        my $i = $self->_parse_children($version, $item);
        delete $i->{taxo};
        $self->_parse_taxo($i, $item);

        push @items, $i;
    }
    return \@items;
}

sub _parse_children
{
    my $self    = shift;
    my $version = shift;
    my $root    = shift;

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
            "./*[not(contains(name(), ':'))]" : "./*[starts-with(name(), '$prefix:')]";

        # now, for each node that we can cover, go and parse
        foreach my $node ($xc->findnodes($xpath, $root)) {
            my $val;
            if ($xc->findnodes('./*', $node)) {
#                print STDERR "Parsing ", $node->getName(), " (recurse)\n";
                $val = $self->_parse_children($version, $node);
            } else {
#                print STDERR "Parsing ", $node->getName(), "\n";
                my $text = $node->textContent();
                if ($text !~ /\S/) {
                    $text = '';
                }
    
                # argh. it has attributes. we do our little hack...
                if ($node->hasAttributes) {
                    $val = XML::RSS::LibXML::MagicElement->new(
                        content => $text,
                        attributes => [ $node->attributes ]
                    );
                } else {
                    $val = $text;
                }
            }
            
            # multiple values for the same key will
            # be stored as an arrayref instead of a scalar
            if (!defined $sub{$node->localname}) {
                $sub{$node->localname} = $val;
            } elsif (ref $sub{$node->localname} eq 'ARRAY') {
                push @{ $sub{$node->localname} }, $val;
            } else {
                $sub{$node->localname} = [ $sub{$node->localname}, $val ];
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

__END__

=head1 NAME 

XML::RSS::LibXML::Parser - RSS Parser for XML::RSS::LibXML

=head1 SYNOPSIS

  use XML::RSS::LibXML;
  use XML::RSS::LibXML::Parser;

  my $rss = XML::RSS::LibXML->new;
  my $p   = XML::RSS::LiBXML::Parser->new;

  $p->parsefile($rss, $file);
  $p->parse($rss, $string);

=head1 DESCRIPTION

XML::RSS::LibXML::Parser parses RSS files and appropriately populates the
data structures in XML::RSS::LibXML

=head1 METHODS

=head2 new

Create a new parser.

=head2 parsefile($rss, $file)

Parses an RSS file $file and populate $rss with its data.

=head2 parse($rss, $string)

Parses an RSS string and populate $rss with its data.

=head1 AUTHOR

Copyright (c) 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>.
Development partially funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=cut