#!/usr/local/bin/perl

# example.pl -abc edit -xyz
# -abc
# command is edit
# -y
# -z
# -x
#
# example.pl -abc tag -xyz
# -abc
# command is edit
# -xyz

use Data::Dumper;
use warnings;
use strict;

	use EasyArgs 
	( 
		'EzArgs',
		DecomposeLevel => ['^(tag|edit|lock|unlock)$'],
		ParseIfNeeded=>[],
	);

	my %hash1 = EzArgs;
	print join("\n", keys(%hash1)) . "\n";


	# get the cvs command that actually occurred on the command line
	my $command = EzArgs('SeparatorValue');
	print "command is $command\n";

	# move to the next level of arguments 
	EzArgs('GoNextLevel');

	# each cvs command can parse the arguments differently.
	if($command eq 'tag')
		{
		EzArgs('ArgumentsThatConsumeNextArgument',"-l");
		}
	elsif($command eq 'edit')
		{
		EzArgs('AtomizeSingleDashArguments');
		}


	my %hash2 = EzArgs;
	print join("\n", keys(%hash2)) . "\n";

