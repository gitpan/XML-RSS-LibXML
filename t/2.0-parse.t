# $Id: 2.0-parse.t 20 2005-10-18 09:41:09Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 35);
use File::Temp qw(tempfile unlink0);
BEGIN { use_ok("XML::RSS::LibXML") }

use constant RSS_CHANNEL_TITLE => "Example 2.0 Channel";
my $version = '2.0';
my $file    = "t/data/rss20.xml";

my $xml = XML::RSS::LibXML->new();
isa_ok($xml,"XML::RSS::LibXML");

eval { $xml->parsefile($file); };
ok(!$@, "Expected to parse RSS feed from file: $@");
analyze_rss($xml);

my $content = do { local $/ = undef; open(F, $file) or die; <F> };
ok(!$@, "Read file into memory: $@");
eval { $xml->parse($content) };
ok(!$@, "Expected to parse RSS feed from string: $@");
analyze_rss($xml);

sub analyze_rss
{
    my $xml = shift;

    is($xml->{'_internal'}{'version'}, $version,
        sprintf("Expected version %s, got %s", $version, $xml->{'_internal'}{'version'}));
    is($xml->{channel}->{'title'},RSS_CHANNEL_TITLE,"Feed title is ".RSS_CHANNEL_TITLE);
    is(ref($xml->{items}),"ARRAY","\$xml->{items} is an ARRAY ref");

    is($xml->{channel}->{category}, 'Reference/Libraries/Library_and_Information_Science/Technical_Services/Cataloguing/Metadata/RDF/Applications/RSS/', "channel category matches");
    is($xml->{channel}->{category}->{domain}, 'http://www.dmoz.org', "channel category domain attribute matches");
    
    foreach my $item ($xml->items) {
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

    $xml2->parse($xml->as_string(0));
    is_deeply($xml, $xml2, "Reparse produces the same structure (no format)");

    my($tmp_fh, $tmp_fn) = tempfile();
    $xml->save($tmp_fn);
    $xml2->parsefile($tmp_fn);
    is_deeply($xml, $xml2, "Reparse produces the same structure (save -> parsefile)");
    unlink0($tmp_fh, $tmp_fn);
}
