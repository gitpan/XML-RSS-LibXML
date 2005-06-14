#!perl
use strict;
use Benchmark qw(cmpthese);
use XML::RSS;
use XML::RSS::LibXML;

my @files = @ARGV;
my $i_rl = 0;
my $i_r = 0;

cmpthese(1000, {
    rss_libxml => \&rss_libxml,
    rss        => \&rss
});

sub rss_libxml
{
    my $rss = XML::RSS::LibXML->new;
    my $file = $files[$i_rl];
    $rss->parsefile($file);

    if ($i_rl == $#files) {
        $i_rl = 0;
    } else {
        $i_rl++;
    }
}

sub rss
{
    my $rss = XML::RSS->new;
    my $file = $files[$i_r];
    $rss->parsefile($file);

    if ($i_r == $#files) {
        $i_r = 0;
    } else {
        $i_r++;
    }
}