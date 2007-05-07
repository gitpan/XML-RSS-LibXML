#!perl
use strict;
use inc::Module::Install;

name('XML-RSS-LibXML');
all_from('lib/XML/RSS/LibXML.pm');

requires 'Encode';
requires 'XML::LibXML';
requires 'XML::LibXML::XPathContext';

auto_install;
WriteAll;
