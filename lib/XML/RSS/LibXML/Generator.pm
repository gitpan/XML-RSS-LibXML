# $Id: Generator.pm 17 2005-08-17 05:05:21Z daisuke $
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
    my %args  = @_;

    while (my($key, $value) = each %args) {
        $rss->{$key} = $value;
    }
}

sub channel
{
    my $self = shift;
    my $rss  = shift;
    $self->set_values($rss->{channel}, @_)
}

sub image
{
    my $self = shift;
    my $rss  = shift;
    $self->set_values($rss->{image}, @_)
}

sub textinput
{
    my $self = shift;
    my $rss  = shift;
    $self->set_values($rss->{textinput}, @_)
}

sub add_item
{
    my $self = shift;
    my $rss  = shift;

    my $item = {};
    $self->set_values($item, @_);

    $rss->{items} ||= [];
    push @{$rss->{items}}, $item;
}

1;
