#!/usr/bin/perl 

use warnings;
use strict;
use Data::Dumper;

use Class1;

my $obj=Class1->new( name=>'Joe', age=>23 );


$obj->Class1;

$obj->Class2;

print Dumper $obj;

