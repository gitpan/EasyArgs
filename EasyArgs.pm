package EasyArgs;

require 5.005_62;
use strict;
use warnings;


our $VERSION = '0.03';


#######################################################
#
# a single argument level are all the arguments that
# occur on the command line between two separators.
# common separators would include something like '--'
#
# each level is treated as its own object
#
# all arguments are stuffed into a single level at startup,
# and then the user can decompose them into different
# levels at runtime.
#
#######################################################

package EasyArgs::SingleArgumentLevel;
use warnings;
use strict;
use Carp;
use Data::Dumper;

#######################################################
sub New
#######################################################
{
	my $inv = shift(@_);
	my $pkg = ref($inv) || $inv;

	my $obj = 
		{ 
		Arguments => [ @_ ],

		};
	return bless ($obj, $pkg);

}

#######################################################
# take an object and a regular expression string
# decompose the object into two objects,
# splitting the object at the argument that matches the regexp
#
# in no separator regexp is provided, the method will
# separate on a double dash argument.
#######################################################
sub DecomposeLevel
#######################################################
{
	my($parent_obj,$separator)=@_;

	$separator='^\-\-$' unless(defined($separator));

	my @unclaimed_arguments = @{$parent_obj->{Arguments}};

	$parent_obj->{Arguments}=[];
	$parent_obj->{Cache}={};
	$parent_obj->{Used}={};

	while(scalar(@unclaimed_arguments))
		{
		my $arg = shift(@unclaimed_arguments);
		if ($arg =~ /$separator/)
			{
			$parent_obj->{SeparatorValue}=$arg;
			last;
			}
		push(@{$parent_obj->{Arguments}}, $arg);
		}

	my $child_obj = $parent_obj->New (@unclaimed_arguments);

	$parent_obj->{NextLevel}=$child_obj;
	$child_obj->{PrevLevel}=$parent_obj;
}


#######################################################
sub SetDuplicateArgResponse
#######################################################
{
	my ($obj, $response)=@_;

	unless (
		   ($response eq 'die') 		# replace the arg value and die
		or ($response eq 'warn')		# replace the arg value and warn about it
		or ($response eq 'replace')		# replace the arg value silently
		or ($response eq 'accumulate')	# accumulate all values that are associated with this arg name.
		)
		{
		croak "Error: SetDuplicateArgResponse expected 'die' 'warn' or 'ignore' ";
		}

	$obj->{DuplicateArgResponseKey}=$response;
}


#######################################################
# pass in a list of argument patterns that consume the next argument
# example, '-l' is a logfile argument that will consume the
# next argument and assume that the next argument is the
# actual name of the logfile.
#
# ('-l', '-o', '-output');
#######################################################
sub ArgumentsThatConsumeNextArgument
#######################################################
{
	my $obj = shift(@_);

	my %hash = map { $_, 1 } @_;

	$obj->{ArgumentsThatConsumeNextArgumentKey}= \%hash;
}



#######################################################
# split any equal signs into arg/val pairs.
#######################################################
sub split_assignment_into_arg_value_pair
#######################################################
{
	return (split(/\=/, $_[0])); 
}

#######################################################
sub SetAtomizer
#######################################################
{
	my ($obj, $code_ref) = @_;
	$obj->{AtomizerCodeRef}=$code_ref;
}


#######################################################
# ls -alt --verbose -+output  
# translates into  
# ls -a -l -t --verbose -+output
#######################################################
sub atomize_dash_arguments_subroutine
#######################################################
{
	my ($flag,$val) = split_assignment_into_arg_value_pair($_[0]);

	my @pairs = ($flag,$val);

	if($flag=~s/^(\-)(\w)/$2/)
		{
		my @chars=split(//,$flag);
		@pairs=map{'-'.$_,$val} @chars;
		}

	return (@pairs);
}

#######################################################
sub AtomizeSingleDashArguments
#######################################################
{
	$_[0]->SetAtomizer ( \&atomize_dash_arguments_subroutine );
}

#######################################################
# atomize and cache the arguments.
# pass in a code reference to a subroutine that will
# determine whether or not a specific argument gets atomized.
# if no code ref is passed in, then no atomizing will occur.
#######################################################
sub ParseArgumentsForThisLevel
#######################################################
{
	my ($obj)=@_;

	$obj->{AtomizerCodeRef}=\&split_assignment_into_arg_value_pair unless(exists($obj->{AtomizerCodeRef}));
	my  $atomizer_code_ref = $obj->{AtomizerCodeRef};

	$obj->{DuplicateArgResponseKey}='replace' unless(exists($obj->{DuplicateArgResponseKey}));
	my $duplicate_response = $obj->{DuplicateArgResponseKey};

	my @results;
	$obj->{Cache}={};
	$obj->{Used}={};

	for(my $index=0; $index<scalar(@{$obj->{Arguments}}); $index++)
		{
		my $cur_arg = $obj->{Arguments}->[$index];

		if(exists($obj->{ArgumentsThatConsumeNextArgumentKey}->{$cur_arg}))
			{ 
			$index++;
			my $assign_value = $obj->{Arguments}->[$index];
			$cur_arg = $cur_arg . '=' . $assign_value;
			}

		# call the user routine that will atomize a single argument
		# return value is an array of key/value pairs
		# (value is undef unless the argument is assigned some value,
		# such as -log=filename.txt)
		my @argument_atoms = &$atomizer_code_ref($cur_arg);

		# take all the arg/value pairs and cache them away. check for uniqueness.
		while(@argument_atoms)
			{
			my ($key,$val) = splice(@argument_atoms, 0, 2);

				{
				if($duplicate_response eq 'accumulate')
					{
					if(exists($obj->{Cache}->{$key}))
						{
						# silent
						# if Cache doesn't have an array ref for this item, create one.
						unless(ref($obj->{Cache}->{$key}) eq 'ARRAY')
							{
							my $old_val = $obj->{Cache}->{$key};
							$obj->{Cache}->{$key} = [ $old_val ];
							}
						push(@{$obj->{Cache}->{$key}}, $val);
						}
					else
						{
						$obj->{Cache}->{$key}=$val;
						}
					}
				else
					{
					if(exists($obj->{Cache}->{$key}))
						{
						my $msg = "$duplicate_response: duplicate command line argument '$key' \n";
						if($duplicate_response eq 'die')
							{
							die $msg;
							}
						elsif($duplicate_response eq 'warn')
							{
							warn $msg;
							}
						elsif($duplicate_response eq 'replace')
							{
							# silently replace
							}
						}
					$obj->{Cache}->{$key}=$val;
					}

				}
			}
		}
}

#######################################################
#######################################################
#######################################################
# the following methods simplify the interface to the
# individual level.
#######################################################
#######################################################
#######################################################
sub ParseIfNeeded
{
	return if (exists($_[0]->{Cache}));
	$_[0]->ParseArgumentsForThisLevel;
}

#######################################################
# return the separator value at this level
#######################################################
sub SeparatorValue
#######################################################
{
	$_[0]->ParseIfNeeded;
	return ($_[0]->{SeparatorValue});
}



#######################################################
# return all args at this level
#######################################################
sub Arguments
#######################################################
{
	$_[0]->ParseIfNeeded;
	return (keys(%{$_[0]->{Cache}}));
}



#######################################################
# return all arg/value pairs
#######################################################
sub Values
#######################################################
{
	$_[0]->ParseIfNeeded;
	return (%{$_[0]->{Cache}});
}


#######################################################
# given a specific argument string, its value at current level
#######################################################
sub Value
#######################################################
{
	$_[0]->ParseIfNeeded;
	$_[0]->{Used}->{$_[1]}=1;
	return ($_[0]->{Cache}->{$_[1]});
}



#######################################################
# given a specific argument string, indicate whether it exists at current level.
# note that some arguments may exists, but have an undef value.
#######################################################
sub Exists
#######################################################
{
	$_[0]->ParseIfNeeded;
	$_[0]->{Used}->{$_[1]}=1;
	return exists($_[0]->{Cache}->{$_[1]});
}


#######################################################
sub Unused
#######################################################
{
	my $obj=$_[0];
	my %return;
	while ( my ($key,$val) = each(%{$obj->{Cache}}) )
		{
		next if (exists($obj->{Used}->{$key}));
		$return{$key}=$val;
		}	

	return (%return);
}



#######################################################
#######################################################
#######################################################
package EasyArgs;
#######################################################
#######################################################
#######################################################

use warnings;
use strict;

use Carp;

use Data::Dumper;



#######################################################
sub caller_string
#######################################################
{
	my ($pkg, $file, $line) = caller(1);
	my $caller_string = "within package '$pkg', filename '$file', line $line. ";
	return $caller_string
}


#######################################################
#######################################################
#######################################################
our $master_object;
#######################################################
#######################################################
#######################################################


my $ArgsHaveBeenConfigured;
#######################################################
# immediately slurp in the @ARGV array and put it into an 
# initial, raw, object with no level separation. 
# If user passed methods via "use" statement,
# then will need an object to perform those methods upon.
#######################################################
BEGIN 
#######################################################
{ 
	$ArgsHaveBeenConfigured=0; 

	$master_object->{OriginalArgs}=[@ARGV];
	my $initial_level=EasyArgs::SingleArgumentLevel->New(@ARGV);
	$master_object->{CurrentLevel}=$initial_level;

	bless($master_object, 'EasyArgs');

	@ARGV=();



}


#######################################################
sub DecomposeLevel
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}
	my $separator=shift(@_);

	$obj->{CurrentLevel}->DecomposeLevel($separator);
}


#######################################################
sub ParseIfNeeded
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}
	my $separator=shift(@_);

	$obj->{CurrentLevel}->ParseIfNeeded($separator);
}

#######################################################
sub SetDuplicateArgResponse
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}
	my $response=shift(@_);

	$obj->{CurrentLevel}->SetDuplicateArgResponse($response);
}


#######################################################
sub ArgumentsThatConsumeNextArgument
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}

	$obj->{CurrentLevel}->ArgumentsThatConsumeNextArgument(@_);
}



#######################################################
sub AtomizeSingleDashArguments
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}

	$obj->{CurrentLevel}->AtomizeSingleDashArguments(@_);
}


#######################################################
sub ParseArgumentsForThisLevel
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}
	my $code_ref=shift(@_);

	$obj->{CurrentLevel}->ParseArgumentsForThisLevel($code_ref);
}



#######################################################
# when a level is decomposed into two levels,
# the levels form a linked list. Use these methods
# to navigate up and down the linked list.
#######################################################

#######################################################
sub GoNextLevel
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}

	if(exists($obj->{CurrentLevel}->{NextLevel}))
		{
		$obj->{CurrentLevel} = $obj->{CurrentLevel}->{NextLevel};
		}
}

#######################################################
sub GoPrevLevel
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}

	if(exists($obj->{CurrentLevel}->{PrevLevel}))
		{
		$obj->{CurrentLevel} = $obj->{CurrentLevel}->{PrevLevel};
		}
}


#######################################################
#######################################################
#######################################################
# The following methods work on a single argument level
#######################################################
#######################################################
#######################################################


#######################################################
sub SeparatorValue
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}
	my $level = $obj->{CurrentLevel};

	return ($level->SeparatorValue);
}


#######################################################
sub Arguments
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}
	my $level = $obj->{CurrentLevel};

	return ($level->Arguments);
}


#######################################################
sub Values
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}
	my $level = $obj->{CurrentLevel};

	return ($level->Values);
}


#######################################################
# given a specific argument string, its value at current level
#######################################################
sub Value
#######################################################
{

	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}
	my $level = $obj->{CurrentLevel};

	my $arg = shift(@_);

	return ($level->Value($arg));

}



#######################################################
# given a specific argument string, indicate whether it exists at current level
#######################################################
sub Exists
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}
	my $level = $obj->{CurrentLevel};

	my $arg = shift(@_);

	return ($level->Exists($arg));
}


#######################################################
# return a hash of all the unused arguments at the current level
#######################################################
sub Unused
#######################################################
{
	my $obj=$master_object;
	if(ref($_[0]))
		{
		$obj=shift(@_);
		}
	my $level = $obj->{CurrentLevel};

	return ($level->Unused);
}



#######################################################
sub EzArgs
#######################################################
{
	my @params = @_;  # @_=();

	# if user calls EzArgs with absolutely no arguments,
	# then assume is is shorthand for calling the "Values" method
	# which returns a hash of arg/value pairs.
	push(@params, "Values") unless(scalar(@params));

	my $method = shift(@params);

	# if user passes in an parameter, "-l" for example,
	# (something that starts with a '-' or '+')
	# then assume it is a command line argument and
	# call Exists on it.
	if($method =~ /^[\-\+]/)
		{
		push(@params,$method);
		$method="Exists";
		}

	return ($master_object->$method(@params));

}

#######################################################
sub ImportEzArgs
#######################################################
{

	my ($pkg, $file, $line);
	$pkg = __PACKAGE__;
	my $counter=1;
	while($pkg eq __PACKAGE__)
		{
		($pkg, $file, $line) = caller($counter++);
		}

	no strict;
	no warnings;

	my $eval_string = '*'.$pkg.'::EzArgs=\&EasyArgs::EzArgs;';

	eval $eval_string ;
}

#######################################################
#######################################################
#######################################################
# the 'import' method gets called when the user says:
#    use EasyArgs;
# The user can pass in a list of method calls paired with
# anonymous arrays containing any arguments to pass into
# those method calls.
# for example:
#
# use EasyArgs 
# (  
#	DecomposeLevel => [],
#	ArgumentsThatConsumeNextArgument => ['-l'],
#	AtomizeSingleDashArguments => [],
#	ParseArgumentsForThisLevel => [],
# );
#
#
#######################################################
#######################################################
#######################################################

#######################################################
sub import
#######################################################
{
	my $pkg=shift(@_);

	if(scalar(@_))
		{

		if($_[0] eq 'EzArgs')
			{
			shift(@_);
			$master_object->ImportEzArgs;
			}

		no warnings;
		no strict;
		while ( scalar (@_) )
			{
			my ($method, $arguments) = splice ( @_, 0, 2);
			$master_object->$method(@$arguments);
			}

		}


}



1;



__END__

=head1 NAME

EasyArgs - Perl module for easily handling command line arguments.

=head1 SYNOPSIS

	use EasyArgs('EzArgs');

	my %args = EzArgs;

	if(exists($args{'-l'}))
		{
		print "-l log file value is ". ($args{'-l'}) ."\n";
		}


=head1 DESCRIPTION

EasyArgs is Yet Another module for parsing command line arguments.

( The first being Getopt::Long and Getopt::Short, which comes standard with perl.
The second being Getopt::Declare by Damian Conway, available on CPAN)

EasyArgs was designed to be easy to use for basic argument handling.

In its simplest form, you can use the module and import the one exportable
subroutine called EzArgs.

	use EasyArgs('EzArgs');

This will set up the module to parse the command line arguments in
its basic, default configuration. 

The "EzArgs" subroutine is exported into the namespace where "use" 
was called. EzArgs is a subroutine that provides a simple interface
to most argument parsing needs. 

=head2 GET ALL ARGUMENT/VALUE PAIRS:

Calling EzArgs with no parameters will return a hash containing all
the Argument/Value pairs on the command line. You can then use that
hash to test for the existence of an argument and for that argument's value.

	my %arg_hash = EzArgs;
	
	if(exists($args{'-l'}))
		{
		my $value = $args{'-l'};
		print "-l log file value is $value \n";
		}

	%> script.pl -l=output.txt
	-l log file is output.txt

=head2 TEST FOR EXISTENCE OF AN ARGUMENT:

You can pass EzArgs the string 'Exists' and the name of the argument,
and the subroutine will return a boolean indicating whether or not
that argument exists on the command line.

	die "help is unavailable \n" if(EzArgs('Exists', 'help'));

Existence shortcut:

If the argument begins with [+-], then you can simply pass in the argument.
EzArgs will assume you are testing that arguments existence.

	print "verbose mode on\n" if(EzArgs('-v'));


=head2 GET THE VALUE FOR AN ARGUMENT:

You can pass EzArgs the string 'Value' and the name of the argument,
and the subroutine will return the value associated with that argument.

	my $log=EzArgs('Value', '-l');
	open(my $fh, '>'.$log) or die;


=head2 TESTING FOR UNUSED ARGUMENTS

Calling EzArgs('Exists', $arg) or EzArgs('Value', $arg) will mark
an internal flag that $arg has been "used". The flag indicates that
the user has "used" that argument in some way in the program.

Once you have tested ('Value', 'Exists') for all arguments that the 
program will use, you can get the "unused" arguments and handle them 
as you wish. This is a good and easy way to report unhandled arguments 
as an error.

	
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




=head1 OPTIONS AVALAILABLE WHEN USING EASYARGS

When you "use EasyArgs", you can pass it additional information
that tells it how to parse the command line arguments.
This is in the form of Method/Parameter pairs that are included
on the use EasyArgs line. The parameters are passed as an array ref
so that any number of parameters can be passed to the method call.

	use EasyArgs
		(
		MethodName => [ parm1, parm2 ],
		);


=head2 VALUE ASSOCIATION

By default, any command line argument that contains an equal sign ('=')
will be split into an argument=value pair. You can further specify that
certain arguments will use the next argument to contain its value.
A common example is the -l argument for a logfile or -f for a input file.

	%> script.pl -l output.log -f input.txt

By default, EasyArgs will parse this as four arguments, "-l", "output.log",
"-f", and "input.txt"

You can tell EasyArgs that the value associated with "-l" and "-f" is specified
in the argument that follows it.

	use EasyArgs
		(
		'EzArgs',
		ArgumentsThatConsumeNextArgument => ['-l', '-f'],
		);

=head2 ARGUMENT ATOMIZATION

Some programs allow the user to specify multiple single-character
switches at the same time. The Unix "ls" command allows this:

	%> ls -alt

The ls program interprets this as three arguments, '-a', '-l', '-t'.
Other programs might wish to interpret this as a single argument '-alt'.

	%> aircraft.pl -alt=30000

EasyArgs refers to the "ls" approach to arguments as "atomization".
A molecule of arguments, "-alt", are atomized into individual switches.

=head2 ATOMIZE SINGLE DASH ARGUMENTS

You can specify to EasyArgs to atomize all single dash arguments (/\-\w/)
and leave all other arguments alone.

	use EasyArgs
		(
		'EzArgs',
		AtomizeSingleDashArguments=>[],
		);
	print "-v verbose mode on\n" if (EzArgs('-v'));

	%> aircraft.pl -vt --alt=30000
	-v verbose mode on

=head2 ATOMIZE ARBITRARY ARGUMENTS

If single dash atomizing isn't quite it for you, you can specify your
own method for argument atomization when you use EasyArgs. 

	use EasyArgs
		(
		SetAtomizer=>
			[
			sub { return $_[0]; }
			],
		);


The subroutine receives the full argument, ("-alt=3"), and
must return a list of argument/value pairs (-a,3,-l,3,-t,3).
Use this with caution.

=head1 ARGUMENT LEVELS

EasyArgs allows you to parse arguments differently based on what "level" 
they are contained in. Levels are separated by some argument on the command
line which matches some regular expression. The most common level separator
is "--".

You could write a perl script that interfaces between the user and some
other program. The interface script might take its own arguments which
get parsed one way, but then the user may need to pass in other argumetns
which get passed directly to the second program.

For example, a script that interfaces between a user and the Unix "ls" command
might be executed by the user like this:

	%> ls_interface.pl -verbose -all -- -alt

Another example of argument "levels" is the "cvs" command, which has
global arguments and command specific arguments. The arguments before
the "command" are one level, the arguments after the "command" are another
level.  (examples of cvs commands are "tag", "edit", "lock", etc)

	%> cvs -v tag -c yada


=head2 LEVEL EXAMPLES

The method to split the arguments into levels is 'DecomposeLevel'.
You can then move from one level to the next with 
'GoNextLevel' and 'GoPrevLevel'. 

The "ls" interface script could use EasyArgs like this:

	use EasyArgs 
	( 
		'EzArgs',
		DecomposeLevel => [],		# split on "--"
		GoNextLevel => [],		# go to arguments after "--"
		AtomizeSingleDashArguments=>[], # atomize args after "--"
	);

	my %args = EzArgs;

	print join("\n", keys(%args));

	%> example.pl -abc -- -xyz
	-y
	-z
	-x

=head2 LEVEL PROGRAMMING

A cvs interface script could parse the first level of arguments.
And then based on the command, parse the second level of arguments
in a manner specific to that command.

	# split the first level, looking for the cvs command.
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

	%> example.pl -abc edit -xyz
	-abc
	command is edit
	-y
	-z
	-x


=head2 EXPORT

None by default.

sub EzArgs can be exported by the "use" statement.
You must pass the string 'EzArgs' to the use EasyArgs 
statement as the first parameter.

	use EasyArgs('EzArgs');

=head1 AUTHOR

Greg London
http://www.greglondon.com

=head1 COPYRIGHT NOTICE

Copyright (c) 2002 Greg London. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Getopt::Declare is a much more advanced command line argument parser.
If EasyArgs doesn't do the job, take a look at Getopt::Declare.

=cut
