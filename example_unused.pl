
	use EasyArgs('EzArgs');
	
	if(EzArgs('-l'))
		{
		my $value = EzArgs('Value','-l');
		print "-l log file value is $value \n";
		}

	my %hash = EzArgs('Unused');
	my @keys = keys(%hash);
	die "Unhandled arguments: ". (join(' ', @keys)) ."\n" if(@keys);

	# %> script.pl -l=output.txt -v
	# -l log file is output.txt
	# Unhandled arguments: -v


