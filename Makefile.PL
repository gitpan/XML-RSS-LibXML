#!perl
use strict;
use inc::Module::Install;

name('XML-RSS-LibXML');
all_from('lib/XML/RSS/LibXML.pm');

requires 'Class::Accessor::Fast';
requires 'DateTime::Format::Mail';
requires 'DateTime::Format::W3CDTF';
requires 'XML::LibXML';
requires 'XML::LibXML::XPathContext';
requires 'UNIVERSAL::require';

tests 't/*.t t/*/*.t';
auto_install;
WriteAll;
