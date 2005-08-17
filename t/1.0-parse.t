# $Id: 1.0-parse.t 17 2005-08-17 05:05:21Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 20);
BEGIN { use_ok("XML::RSS::LibXML") }

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



my $xml = XML::RSS::LibXML->new();
isa_ok($xml,"XML::RSS::LibXML");

$xml->add_module(prefix => "example", uri => "http://example.org/ns#");

eval { $xml->parse(RSS_DOCUMENT); };
is($@,'',"Parsed RSS feed");

is($xml->{'_internal'}->{'version'},
       RSS_VERSION,
       "Is RSS version ".RSS_VERSION);

is($xml->{channel}->{'title'},
       RSS_CHANNEL_TITLE,
       "Feed title is ".RSS_CHANNEL_TITLE);

is($xml->channel->{'title'},
       RSS_CHANNEL_TITLE,
       "Feed title is ".RSS_CHANNEL_TITLE);

is(ref($xml->{items}),
       "ARRAY",
       "\$xml->{items} is an ARRAY ref");

foreach my $item (@{$xml->{items}}) {
    foreach my $el ("title","link","description") {
        ok($item->{$el}, "$el exists for item $item->{link}");
    }
}

is $xml->{items}->[1]->{dc}->{date}, "2005-08-23T07:00+00:00";
is $xml->{items}->[1]->{content}->{encoded}, 'TEST';
is $xml->{items}->[1]->{example}->{foo}, "bar";

is $xml->{items}->[1]->{'http://purl.org/dc/elements/1.1/'}->{date}, "2005-08-23T07:00+00:00";
is $xml->{items}->[1]->{'http://purl.org/rss/1.0/modules/content/'}->{encoded}, 'TEST';
is $xml->{items}->[1]->{'http://example.org/ns#'}->{foo}, "bar";

my $xml2 = XML::RSS::LibXML->new;
$xml2->add_module(prefix => "example", uri => "http://example.org/ns#");
$xml2->parse($xml->as_string());

foreach my $p (grep { /^_/ } keys %{$xml}) {
    delete $xml->{$p};
    delete $xml2->{$p};
}

is_deeply($xml, $xml2, "Reparse produces same structure");
