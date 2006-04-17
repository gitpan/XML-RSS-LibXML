use strict;
use Test::More;
BEGIN
{
    eval { require Encode };
    if ($@) {
        plan(skip_all => "This test requires Encode.pm");
    } else {
        plan(tests => 3);
        Encode->import();
    }
}

BEGIN { use_ok("XML::RSS::LibXML") }

my $rss = XML::RSS::LibXML->new();

ok($rss->parsefile('t/data/rss-euc.xml'));

is($rss->channel('title'), decode('euc-jp', 'RSS 1.0チャンネル例'));

1;