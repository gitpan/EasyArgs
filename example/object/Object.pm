
package Object;

use warnings;
use strict;
use Data::Dumper;

use base EasyArgs;

sub new
{
	my $inv=shift(@_);
	my $pkg = ref($inv) || $inv;


	my $obj = { @_ };

	bless($obj, $pkg);

	$obj->EasyArgs_New;

	return $obj;
}


sub dumper
{
	my $obj=shift;

	print "dumping contents of object, $obj \n";
	print Dumper $obj;
}


1;


