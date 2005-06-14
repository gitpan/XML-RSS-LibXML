#!perl
# $Id: Build.PL 2 2005-06-14 02:52:09Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;

my $build = Module::Build->new(
    dist_name => 'XML-RSS-LibXML',
    dist_version_from => 'lib/XMl/RSS/LibXML.pm',
    requires => {
        'XML::LibXML' => 0,
        'XML::LibXML::XPathContext' => 0
    },
    build_requires => {
        'Test::More' => 0
    },
    license => 'perl',
    create_makefile_pl => 'traditional',
);
$build->create_build_script;