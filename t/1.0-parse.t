# $Id: 1.0-parse.t 7 2005-06-20 07:16:01Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More;

use constant RSS_VERSION       => "1.0";
use constant RSS_CHANNEL_TITLE => "Example 1.0 Channel";
use constant RSS_DEFAULTNS     => "http://purl.org/rss/1.0/";

use constant RSS_DOCUMENT      => qq(<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:example="http://example.org/ns#"
>

<channel rdf:about="http://rc3.org/">
<title>Example 1.0 Channel</title>
<link>http://example.com</link>
<description>To lead by example</description>
<dc:language>en-us</dc:language>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://example.com/2002/09/02" />
  <rdf:li rdf:resource="http://example.com/2002/09/01" />
 </rdf:Seq>
</items>
</channel>

<item rdf:about="http://example.com/2002/09/02">
 <title>News for September the Second</title>
 <link>http://example.com/2002/09/02</link>
 <description>other things happened today</description>
</item>

<item rdf:about="http://example.com/2002/09/01">
 <title>News for September the First</title>
 <link>http://example.com/2002/09/01</link>
 <description>something happened today</description>
 <content:encoded><![CDATA[TEST]]></content:encoded>
 <dc:date>2005-08-23T07:00+00:00</dc:date>
 <example:foo>bar</example:foo>
</item>

</rdf:RDF>
);

plan tests => 14;

use_ok("XML::RSS::LibXML");

my $xml = XML::RSS::LibXML->new();
isa_ok($xml,"XML::RSS::LibXML");

$xml->add_module(prefix => "example", uri => "http://example.org/ns#");

eval { $xml->parse(RSS_DOCUMENT); };
is($@,'',"Parsed RSS feed");

cmp_ok($xml->{'_internal'}->{'version'},
       "eq",
       RSS_VERSION,
       "Is RSS version ".RSS_VERSION);

# XXX - this is undocumented in XML::RSS, so won't test
# cmp_ok($xml->{namespaces}->{'#default'},
#       "eq",
#       RSS_DEFAULTNS,
#       RSS_DEFAULTNS);

cmp_ok($xml->{channel}->{'title'},
       "eq",
       RSS_CHANNEL_TITLE,
       "Feed title is ".RSS_CHANNEL_TITLE);

cmp_ok($xml->channel->{'title'},
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

is $xml->{items}->[1]->{dc}->{date}, "2005-08-23T07:00+00:00";
is $xml->{items}->[1]->{content}->{encoded}, 'TEST';
is $xml->{items}->[1]->{example}->{foo}, "bar";

is $xml->{items}->[1]->{'http://purl.org/dc/elements/1.1/'}->{date}, "2005-08-23T07:00+00:00";
is $xml->{items}->[1]->{'http://purl.org/rss/1.0/modules/content/'}->{encoded}, 'TEST';
is $xml->{items}->[1]->{'http://example.org/ns#'}->{foo}, "bar";

ok($ok,"All items have title,link and description elements");

