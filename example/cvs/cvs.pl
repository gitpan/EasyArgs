#!/usr/bin/perl 

use warnings;
use strict;
use Data::Dumper;
use EasyArgs;

my $cvs = EasyArgs->EasyArgs_New
	(
	EasyArgs_SeparatorRegexp => '^(Tag|Edit)$',

	EasyArgs_ArgConfig =>
		{
		File =>
				{
				Response => 'Die',
				},
		Undefined =>
				{
				Response => 'Warn',
				}
		}

	);


my $sep = $cvs->EasyArgs_SeparatorValue;

print "Sep is $sep \n";

my $eval_str = "use $sep; \n $sep->new;";
eval($eval_str);
warn $@ if $@;






