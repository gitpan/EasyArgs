#!/usr/local/bin/perl

# perl example_duplicate.pl  -x=first -y -z -x=second
#
# $VAR1 = {
#           '-y' => undef,
#           '-z' => undef,
#           '-x' => [
#                     'first',
#                     'second'
#                   ]
#         };
# 

use Data::Dumper;
use warnings;
use strict;

use EasyArgs 
	( 
		'EzArgs',
		SetDuplicateArgResponse => ['accumulate'], 
	);

my %hash = EzArgs;

print Dumper \%hash;