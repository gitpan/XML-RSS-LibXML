# $Id: 2.0-parse.t 17 2005-08-17 05:05:21Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 16);
BEGIN { use_ok("XML::RSS::LibXML") }

use constant RSS_VERSION       => "2.0";
use constant RSS_CHANNEL_TITLE => "Example 2.0 Channel";

use constant RSS_DOCUMENT      => <<EORSS;
<?xml version="1.0"?>
<rss version="2.0">
 <channel>
  <title>Example 2.0 Channel</title>
  <link>http://example.com/</link>
  <description>To lead by example</description>
  <language>en-us</language>
  <copyright>All content Public Domain, except comments which remains copyright the author</copyright> 
  <managingEditor>editor\@example.com</managingEditor> 
  <webMaster>webmaster\@example.com</webMaster>
  <docs>http://backend.userland.com/rss</docs>
  <category  domain="http://www.dmoz.org">Reference/Libraries/Library_and_Information_Science/Technical_Services/Cataloguing/Metadata/RDF/Applications/RSS/</category>
  <generator>The Superest Dooperest RSS Generator</generator>
  <lastBuildDate>Mon, 02 Sep 2002 03:19:17 GMT</lastBuildDate>
  <ttl>60</ttl>

  <item>
   <title>News for September the Second</title>
   <link>http://example.com/2002/09/02</link>
   <description>other things happened today</description>
   <comments>http://example.com/2002/09/02/comments.html</comments>
   <author>joeuser\@example.com</author>
   <pubDate>Mon, 02 Sep 2002 03:19:00 GMT</pubDate>
   <guid isPermaLink="true">http://example.com/2002/09/02</guid>
   <enclosure url="http://exapmle.com/podcast/20020902.mp3" type="audio/mpeg" length="65535"/>
  </item>

  <item>
   <title>News for September the First</title>
   <link>http://example.com/2002/09/01</link>
   <description>something happened today</description>
   <comments>http://example.com/2002/09/01/comments.html</comments>
   <author>joeuser\@example.com</author>
   <pubDate>Sun, 01 Sep 2002 12:01:00 GMT</pubDate>
   <guid isPermaLink="true">http://example.com/2002/09/02</guid>
   <enclosure url="http://example.com/podcast/20020901.mp3" type="audio/mpeg" length="4096"/>
  </item>

 </channel>
</rss>
EORSS

my $xml = XML::RSS::LibXML->new();
isa_ok($xml,"XML::RSS::LibXML");

eval { $xml->parse(RSS_DOCUMENT); };
is($@,'',"Parsed RSS feed");

is($xml->{'_internal'}->{'version'}, RSS_VERSION,"Is RSS version ".RSS_VERSION);
is($xml->{channel}->{'title'},RSS_CHANNEL_TITLE,"Feed title is ".RSS_CHANNEL_TITLE);
is(ref($xml->{items}),"ARRAY","\$xml->{items} is an ARRAY ref");
is($xml->{channel}->{category}, 'Reference/Libraries/Library_and_Information_Science/Technical_Services/Cataloguing/Metadata/RDF/Applications/RSS/', "channel category matches");
is($xml->{channel}->{category}->{domain}, 'http://www.dmoz.org', "channel category domain attribute matches");

foreach my $item (@{$xml->{items}}) {
  foreach my $el ("title","description") {
    ok($item->{$el}, "$el exists for $item->{link}");
  }
}

my $enclosure = $xml->{items}->[1]->{enclosure};
is($enclosure->{url},'http://example.com/podcast/20020901.mp3', 'enclosure url ok');
is($enclosure->{type},'audio/mpeg', 'enclosure type ok');
is($enclosure->{length}, '4096', 'ebnclosure length ok');

my $xml2 = XML::RSS::LibXML->new();
$xml2->parse($xml->as_string);
is_deeply($xml, $xml2, "Reparse produces the same structure");
