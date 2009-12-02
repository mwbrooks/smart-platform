#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use File::Spec;
use Cwd qw(getcwd);
use Carp qw( confess );

use_ok('RSP::Config');

my $tmp_dir = tempdir();
our $test_config = {
    root => $tmp_dir,
    extensions => 'DataStore',
    server => {
        Root => $tmp_dir,
        ConnectionTimeout => 123,
        MaxRequestsPerClient => 13,
        MaxRequestsPerChild => 23,
        User => 'zim',
        Group => 'aliens',
        MaxClients => 47,
    },
};

basic: {
    my $conf = RSP::Config->new(config => $test_config);
    isa_ok($conf, 'RSP::Config');
}

check_rsp_root_is_correct: {
    my $conf = RSP::Config->new(config => $test_config);
    is($conf->root, $tmp_dir, 'root directory is correct');

    local $test_config = { %$test_config };
    delete $test_config->{root};
    $conf = RSP::Config->new(config => $test_config);
    is($conf->root, getcwd(), 'root defaults to current working directory');

    local $test_config = { %$test_config, root => 'reallyreallyreallyshouldnotexsit' };
    $conf = RSP::Config->new(config => $test_config);
    throws_ok {
        $conf->root
    } qr/Directory '.+?' does not exist/, 'non existant root directory throws exception';
}

check_rsp_exceptions_are_correct: {
    my $conf = RSP::Config->new(config => $test_config);
    is_deeply( $conf->extensions, [qw(RSP::Extension::DataStore)], 'Extensions returned correctly');

    local $test_config = { %$test_config, extensions => 'ThisClassReallyShouldNotExist' };
    $conf = RSP::Config->new(config => $test_config);
    throws_ok {
        $conf->extensions
    } qr/Could not load extension 'RSP::Extension::ThisClassReallyShouldNotExist'/, 
        'Non-existing extension class throws error';
}

