# $Id$
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

# XXX - straight copy from XML-RSS-1.05. May need to tweak for X::R::LibXML

use strict;
use Test::More;

use constant RSS_VERSION       => "0.91";
use constant RSS_CHANNEL_TITLE => "Example 0.91 Channel";

use constant RSS_DOCUMENT      => qq(<?xml version="1.0"?>
<rss version="0.91">
  <channel>
    <title>Example 0.91 Channel</title>
    <link>http://example.com</link>
    <description>To lead by example</description>
  </channel>
  <item>
     <title>News for September the Second</title>
     <link>http://example.com/2002/09/02</link>
     <description>other things happened today</description>
  </item>
  <item>
     <title>News for September the First</title>
     <link>http://example.com/2002/09/01</link>
     <description>something happened today</description>
  </item>
</rss>);

plan tests => 7;

use_ok("XML::RSS::LibXML");

my $xml = XML::RSS::LibXML->new();
isa_ok($xml,"XML::RSS::LibXML");

eval { $xml->parse(RSS_DOCUMENT); };
is($@,'',"Parsed RSS feed");

cmp_ok($xml->{'_internal'}->{'version'},
       "eq",
       RSS_VERSION,
       "Is RSS version ".RSS_VERSION);

cmp_ok($xml->{channel}->{'title'},
       "eq",
       RSS_CHANNEL_TITLE,
       "Feed title is ".RSS_CHANNEL_TITLE);

cmp_ok(ref($xml->{items}),
       "eq",
       "ARRAY",
       "\$xml->{items} is an ARRAY ref");

my $ok = 1;

foreach my $item (@{$xml->{items}}) {

  foreach my $el ("title","link","description") {
    if (! exists $item->{$el}) {
      $ok = 0;
      last;
    }
  }

  last if (! $ok);
}

ok($ok,"All items have title,link and description elements");