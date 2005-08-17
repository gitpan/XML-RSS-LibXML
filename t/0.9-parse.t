# $Id: 0.9-parse.t 17 2005-08-17 05:05:21Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 9);
BEGIN { use_ok("XML::RSS::LibXML") }

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

my $xml = XML::RSS::LibXML->new();
isa_ok($xml,"XML::RSS::LibXML");

eval { $xml->parse(RSS_DOCUMENT); };
is($@,'',"Parsed RSS feed");

is($xml->{'_internal'}->{'version'},
       RSS_VERSION,
       "Is RSS version ".RSS_VERSION);

is($xml->{channel}->{'title'},
       RSS_CHANNEL_TITLE,
       "Feed title is ".RSS_CHANNEL_TITLE);

is(ref($xml->{items}),
       "ARRAY",
       "\$xml->{items} is an ARRAY ref");

foreach my $item (@{$xml->{items}}) {
    foreach my $el qw(title) {
        ok($item->{$el}, "$el exists for item $item->{link}");
    }
}

my $xml2 = XML::RSS::LibXML->new;
$xml2->parse($xml->as_string);
is_deeply($xml, $xml2, "Reparse produces same structure");
