# $Id: Generator.pm 18 2005-08-17 10:20:53Z daisuke $
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
