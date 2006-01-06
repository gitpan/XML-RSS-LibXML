# $Id: Format.pm 23 2005-12-28 09:18:23Z daisuke $
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

__END__

=head1 NAME

XML::RSS::LibXML::Format - Base Class To Format XML::RSS::LibXML

=head1 SYNOPSIS

   package MyFormat;
   use base qw(XML::RSS::Format);

=head1 DESCRIPTION

This is the base class for objects that know how to convert XML::RSS::LibXML
objects to various RSS format.

=head1 METHODS

=head2 new

Create a new object

=head2 format($rss)

Returns the string representation of $rss. Subclasses must implement
this method.

=head1 AUTHOR

Copyright (c) 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>.
Development partially funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=cut
