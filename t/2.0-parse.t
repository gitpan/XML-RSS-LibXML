# $Id: 2.0-parse.t 2 2005-06-14 02:52:09Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More;

use constant RSS_VERSION       => "2.0";
use constant RSS_CHANNEL_TITLE => "Example 2.0 Channel";

use constant RSS_DOCUMENT      => qq(<?xml version="1.0"?>
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
</rss>);

plan tests => 12;

use_ok("XML::RSS::LibXML");

my $xml = XML::RSS::LibXML->new();
isa_ok($xml,"XML::RSS::LibXML");

eval { $xml->parse(RSS_DOCUMENT); };
is($@,'',"Parsed RSS feed");

cmp_ok($xml->{'_internal'}->{'version'},"eq",RSS_VERSION,"Is RSS version ".RSS_VERSION);
cmp_ok($xml->{channel}->{'title'},"eq",RSS_CHANNEL_TITLE,"Feed title is ".RSS_CHANNEL_TITLE);
cmp_ok(ref($xml->{items}),"eq","ARRAY","\$xml->{items} is an ARRAY ref");
is($xml->{channel}->{category}, 'Reference/Libraries/Library_and_Information_Science/Technical_Services/Cataloguing/Metadata/RDF/Applications/RSS/', "channel category matches");
is($xml->{channel}->{category}->{domain}, 'http://www.dmoz.org', "channel category domain attribute matches");
my $ok = 1;

foreach my $item (@{$xml->{items}}) {

  my $min = 0;
  foreach my $el ("title","description") {
    if (exists $item->{$el}) {
      $min ||= 1;
    }
  }

  $ok = $min;
  last if (! $ok);
}

cmp_ok($xml->{items}->[1]->{enclosure}->{url},"eq",'http://example.com/podcast/20020901.mp3');
cmp_ok($xml->{items}->[1]->{enclosure}->{type},"eq",'audio/mpeg');
cmp_ok($xml->{items}->[1]->{enclosure}->{length},"eq",'4096');

ok($ok,"All items have either a title or a description element");

