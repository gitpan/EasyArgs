#!/usr/local/bin/perl



use Data::Dumper;
use warnings;
use strict;

use EasyArgs ( 'EzArgs' );

my %hash = EzArgs;

print Dumper $EasyArgs::master_object;