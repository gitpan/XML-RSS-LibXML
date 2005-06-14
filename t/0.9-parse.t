# $Id: 0.9-parse.t 2 2005-06-14 02:52:09Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More;

plan tests => 7;

use constant RSS_VERSION       => "0.9";
use constant RSS_CHANNEL_TITLE => "Example 0.9 Channel";

use constant RSS_DOCUMENT      => qq(<?xml version="1.0"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns="http://my.netscape.com/rdf/simple/0.9/">

  <channel>
    <title>Example 0.9 Channel</title>
    <link>http://www.example.com</link>
    <description>To lead by example</description>
  </channel>
  <image>
    <title>Mozilla</title>
    <url>http://www.example.com/images/whoisonfirst.gif</url>
    <link>http://www.example.com</link>
  </image>
  <item>
    <title>News for September the second</title>
    <link>http://www.example.com/2002/09/02</link>
  </item>
  <item>
    <title>News for September the first</title>
    <link>http://www.example.com/2002/09/01</link>
  </item>
</rdf:RDF>);

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

  foreach my $el ("title","link") {
    if (! exists $item->{$el}) {
      $ok = 0;
      last;
    }
  }

  last if (! $ok);
}

ok($ok,"All items have title and link elements");
