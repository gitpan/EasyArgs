
package Class1;

use warnings;
use strict;
use Data::Dumper;

use Class2;
use base 'Class2';

use EasyArgs
	(
	EasyArgs_ArgConfig =>
		{
		-f => 	{
				Duplicate => 'Accumulate',
				Assignment => 'Next',
				Help => 'Define input file',
				},
		}
	);

use base 'EasyArgs';


sub new
{
	my $inv=shift(@_);
	my $pkg = ref($inv) || $inv;


	my $obj = { @_ };

	bless($obj, $pkg);

	$obj->EasyArgs_New
	(
	EasyArgs_ArgConfig =>
		{
		Undefined =>
				{
				Response => 'Die',
				}
		}
	);

	return $obj;
}


sub Class1
{
	my $obj=shift;

	if($obj->EasyArgs_Exists('-f'))
		{
		print "-f exists\n";
		}
	else
		{
		print "-f does not exist\n";
		}


}

1;


