

=comment

call this with the following command line:

./cvs.pl Tag -t=tag1 -t=tag2

=cut


package Tag;

use warnings;
use strict;
use Data::Dumper;

use base ('EasyArgs');


sub new
{
	warn "called method new from package Tag";

	my $tag = EasyArgs->EasyArgs_New
		(
		EasyArgs_ArgConfig =>
			{
			-t => 	{
					Duplicate => 'Accumulate',
					Assignment => 'Equal',
					Help => 'Define tag name',
					},
			Undefined =>
				{
				Response => 'Die',
				},
			},
		);

	print Dumper $tag;

}

1;

