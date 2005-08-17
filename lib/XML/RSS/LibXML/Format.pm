# $Id: Format.pm 17 2005-08-17 05:05:21Z daisuke $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML::Format;
use strict;

sub new
{
    my $class = shift;
    bless {}, $class;
}

sub format { die __PACKAGE__ . " must defined format()" }

sub _populate_namespaces
{
    my $self = shift;
    my $rss  = shift;
    my $root = shift;

    while (my($prefix, $url) = each %{$self->{_modules}}) {
        next if $prefix =~ /^rss\d\d$/;
        if ($rss->{channel}{$prefix} ||
            (ref($rss->{items}) eq 'ARRAY' && grep { $_->{$prefix} } @{ $rss->{items} })) {
            $root->setNamespace($url, $prefix, 0);
        }
    }
}

sub _populate_node
{
    my $self   = shift;
    my $node   = shift;
    my $parent = shift;
    my $value  = shift;

    $node->appendText($value);
    foreach my $attr ($value->attributes) {
        $node->setAttribute($attr, $value->{$attr});
    }
    $parent->appendChild($node);
}

sub _populate_from_spec
{
    my $self   = shift;
    my $xml    = shift;
    my $parent = shift;
    my $rss    = shift;
    my $spec_hash = shift;

    my($node, $value);
    while (my($e, $spec) = each %$spec_hash) {
        foreach my $p (@$spec) {
            $value = (ref $p && $rss->{$p->{module}}) ?
                $rss->{$p->{module}}{$p->{element}} :
                $rss->{$p};
            if ($value) {
                if (ref $p) {
                    $self->{_modules}{$p->{module}} ||= $self->{_namespaces}{$p->{module}}
                }
                $node = $xml->createElement($e);
                $node->appendText($value);
                if (eval { $value->isa('XML::RSS::LibXML::MagicElement') }) {
                    foreach my $attr ($value->attributes) {
                        $node->setAttribute($attr, $value->{$attr});
                    }
                }
                $parent->appendChild($node);
                last;
            }
        }
    }
}

1;
