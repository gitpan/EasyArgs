EasyArgs - Perl module for easily handling command line arguments.



EasyArgs is Yet Another module for parsing command line arguments.

( The first being Getopt::Long and Getopt::Short, which comes standard with perl.
The second being Getopt::Declare by Damian Conway, available on CPAN)

EasyArgs was designed to be easy to use for basic argument handling.

	use EasyArgs;


	my $obj = EasyArgs->EasyArgs_New
		(
		EasyArgs_ArgConfig =>
			{
			-f => 	{
					Assignment => 'Next',
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
	


AUTHOR

        Greg London
        http://www.greglondon.com

COPYRIGHT NOTICE

        Copyright (c) 2002 Greg London. All rights reserved.
        This program is free software; you can redistribute it and/or
        modify it under the same terms as Perl itself.




