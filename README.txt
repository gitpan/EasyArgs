EasyArgs - Perl module for easily handling command line arguments.



EasyArgs is Yet Another module for parsing command line arguments.
(The first being Getopt::Declare by Damian Conway, available on CPAN)

EasyArgs was designed to be easy to use for basic argument handling.

In its simplest form, you can use the module and import the one exportable
subroutine called EzArgs.

This will set up the module to parse the command line arguments in
its basic, default configuration. 

	use EasyArgs('EzArgs');

	my %args = EzArgs;

	if(exists($args{'-l'}))
		{
		print "-l log file value is ". ($args{'-l'}) ."\n";
		}


