
package Class2;

use warnings;
use strict;
use Data::Dumper;

use EasyArgs
	(
	EasyArgs_ArgConfig =>
		{
		-v => 	{
				Duplicate => 'Die',
				Assignment => 'None',
				Help => 'Enable Verbosity',
				},
		}
	);

use base 'EasyArgs';


sub Class2
{
	my $obj=shift;


	if($obj->EasyArgs_Exists('-v'))
		{
		print "-v exists\n";
		}
	else
		{
		print "-v does not exist\n";
		}



}


1;


