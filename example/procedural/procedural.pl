#!/usr/local/bin/perl



use Data::Dumper;
use warnings;
use strict;

use EasyArgs;


my $obj = EasyArgs->EasyArgs_New
	(
	EasyArgs_ArgConfig =>
		{
		-f => 	{
				Assignment => 'Next',
				Help => 'Define input file',
				},
		}

	);

if($obj->EasyArgs_Exists('-f'))
	{
	my  $file = $obj->EasyArgs_Value('-f');

	print "file is $file \n";
	
	}
else
	{
	print "no -f option used\n";
	}
