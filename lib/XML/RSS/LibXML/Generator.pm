# $Id: Generator.pm 20 2005-10-18 09:41:09Z daisuke $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML::Generator;
use strict;

sub new { bless {}, shift }

sub set_values
{
    my $self  = shift;
    my $rss   = shift;
    my $local = shift;
    my %args  = @_;

    while (my($key, $value) = each %args) {
        $local->{$key} = $value;
        if (my $ns = $rss->{_namespaces}{$key}) {
            $local->{$ns} = $value;
        }
    }
}

sub channel
{
    my $self = shift;
    my $rss  = shift;
    $rss->{channel} ||= {};
    $self->set_values($rss, $rss->{channel}, @_);
}

sub image
{
    my $self = shift;
    my $rss  = shift;

    $rss->{image} ||= {};
    $self->set_values($rss, $rss->{image}, @_)
}

sub textinput
{
    my $self = shift;
    my $rss  = shift;
    $rss->{textinput} ||= {};
    $self->set_values($rss, $rss->{textinput}, @_)
}

sub add_item
{
    my $self = shift;
    my $rss  = shift;

    my $item = {};
    $self->set_values($rss, $item, @_);
    $rss->{items} ||= [];

    push @{$rss->{items}}, $item;
}

1;

__END__

=head1 NAME

XML::RSS::LibXML::Genrator - Provide API to Generate XML::RSS::LibXML

=head1 SYNOPSIS

  use XML::RSS::LibXML;
  use XML::RSS::LibXML::Genrator;

  my $rss = XML::RSS::LibXMl->new;
  my $g   = XML::RSS::LibXML::Generator->new;

=head1 METHODS

=head2 new

=head2 set_values

=head2 channel

=head2 image

=head2 textinput

=head2 add_item

=head1 AUTHOR

Copyright (c) 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>.
Development partially funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=cut
