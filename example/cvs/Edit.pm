

=comment

call this with the following command line:

./cvs.pl Edit -f file1 -f file2

=cut


package Edit;

use warnings;
use strict;
use Data::Dumper;

use base ('EasyArgs');


sub new
{
	warn "called method new from package edit";

	my $edit = EasyArgs->EasyArgs_New
		(
		EasyArgs_ArgConfig =>
			{
			-f => 	{
					Duplicate => 'Accumulate',
					Assignment => 'Next',
					Help => 'Define input file',
					},
			Undefined =>
				{
				Response => 'Die',
				},
			},
		);

	print Dumper $edit;

}

1;

