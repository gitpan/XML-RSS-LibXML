#!perl
# $Id: /mirror/XML-RSS-LibXML/Build.PL 1103 2005-11-18T07:33:44.704855Z daisuke  $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;

my $class = Module::Build->subclass(code => <<'EOM');
    sub ACTION_disttest
    {
        my $self = shift;
        local $ENV{PERL_TESTPOD} = 1;
        $self->SUPER::ACTION_disttest(@_);
    }

    sub find_test_files
    {
        my $self  = shift;
        my $tests = $self->SUPER::find_test_files(@_);

        return $tests if $ENV{PERL_TESTPOD};
        return [ grep { $_ !~ /\bpod.*\.t\z/ } @$tests ];
    }
EOM

my $build = $class->new(
    dist_name => 'XML-RSS-LibXML',
    dist_version_from => 'lib/XML/RSS/LibXML.pm',
    requires => {
        'Encode'      => 0,
        'XML::LibXML' => 0,
        'XML::LibXML::XPathContext' => 0
    },
    build_requires => {
        'Test::More' => 0
    },
    license => 'perl',
    create_makefile_pl => 'traditional',
    create_readme => 1,
);
$build->create_build_script;