package EasyArgs;

require 5.005_62;
use strict;
use warnings;
use Data::Dumper;
use Carp;

our $VERSION = '1.00';

################################################################################
################################################################################
################################################################################

my $example = <<'EXAMPLE';


use base qw(EasyArgs)
	(
	EasyArgs_ArgConfig =>
		{
		-f => 	{
				Duplicate => 'Accumulate',
				Assignment => 'Next',
				Help => 'Define input file',
				},
		-v =>	{
				Duplicate => 'Die',
				Assignment => 'None',
				Help => 'Enable Verbose mode',
				},
		-lsf =>	{
				Duplicate => 'Die',
				Assignment => '=',
				Valid => '^(big|small|fast)$',
				Default => 'big'
				Help => 'Enable Verbose mode',
				},
		}
	);

my $obj = EasyArgs->EasyArgs_New
	(
	EasyArgs_SeparatorRegexp => '^(tag|edit)$',

	EasyArgs_ArgConfig =>
		{
		Files =>
				{
				Duplicate => 'Die',
				Assignment => 'None',
				},
		Undefined =>
				{
				Response => 'Die',
				}
		}

	);

EXAMPLE
;


################################################################################
################################################################################
################################################################################

################################################################################
################################################################################
################################################################################
# package EasyArgs::SingleArgumentLevel;
################################################################################
################################################################################
################################################################################

use strict;
use warnings;
use Data::Dumper;
use Carp;

################################################################################
# set/get the regular expression used to define/detect the separator argument
# that separates different argument levels
# by default, double-hyphen ('--') is the separator.
################################################################################
sub EasyArgs_SeparatorRegexp
################################################################################
{
	my $obj=shift(@_);
	unless	
	(
		exists($obj->{EasyArgs_SeparatorRegexp})
	and	defined($obj->{EasyArgs_SeparatorRegexp})
	)
		{
		$obj->{EasyArgs_SeparatorRegexp}='^\-\-$';
		}
	$obj->{EasyArgs_SeparatorRegexp}=$_[0] if scalar(@_);
	return $obj->{EasyArgs_SeparatorRegexp};
}



################################################################################
# get the actual string that was detected as the separator value
# if no separator, return undef
################################################################################
sub EasyArgs_SeparatorValue
################################################################################
{
	my $obj=shift(@_);
	unless	
	(
		exists($obj->{EasyArgs_SeparatorValue})
	)
		{
		$obj->{EasyArgs_SeparatorValue}=undef;
		}
	$obj->{EasyArgs_SeparatorValue}=$_[0] if scalar(@_);
	return $obj->{EasyArgs_SeparatorValue};
}


################################################################################
# set/get the regular expression used to detect what arguments get atomized.
# by default, do not atomize anything.
# if you want to atomize single dash options, set it to '^\-\w'
################################################################################
sub EasyArgs_AtomizeRegexp
################################################################################
{
	my $obj=shift(@_);
	unless	
	(
		exists($obj->{EasyArgs_AtomizeRegexp})
	and	defined($obj->{EasyArgs_AtomizeRegexp})
	)
		{
		$obj->{EasyArgs_AtomizeRegexp}='^$';
		}
	$obj->{EasyArgs_AtomizeRegexp}=$_[0] if scalar(@_);
	return $obj->{EasyArgs_AtomizeRegexp};
}



################################################################################
# given an actual argument: '-l', '+define+hello', 'file.txt', '"hello there"',
# return a string indicating what type of argument it is:
# if it is a +- file and the user already defined these types, then
# return the original argument as the type.
# (if -l has been defined, when -l is passed in, return -l)
# (if -l is not   defined, when -l is passed in, return 'Undefined');
# Otherwise, if not starting with a +-, then return it as a "File" type.
################################################################################
sub EasyArgs_Typify
################################################################################
{
	my ($obj, $arg) = @_;

	if($arg =~ /^[\-\+]/)
		{
		my ($key,$val) = split(/\=/, $arg);

		if(exists($obj->{EasyArgs_ArgConfig}->{$key}))
			{
			return $key;
			}
		else
			{
			return 'Undefined';		
			}
		}

	return 'File';


}

################################################################################
# define how to respond to this Type.
# since simple usage model does not require the user to define any arguments,
# the default cause for an undefined response is 'Silent'
# Once the program is stable, it may be useful to set arguments of type 
# "Undefined" to have a "Response" of "Die".
# That way, the program will die on undefined arguments.
# Die, Warn, Silent
################################################################################
sub EasyArgs_Response
################################################################################
{
	my $obj = shift;
	my $type = shift;

	unless
	(
		exists($obj->{EasyArgs_ArgConfig}->{$type}->{Response})
	and	defined($obj->{EasyArgs_ArgConfig}->{$type}->{Response})
	)
		{
		$obj->{EasyArgs_ArgConfig}->{$type}->{Response}='Silent';
		}
	$obj->{EasyArgs_ArgConfig}->{$type}->{Response}=$_[0] if(scalar(@_));
	return $obj->{EasyArgs_ArgConfig}->{$type}->{Response};
}
	

################################################################################
# Define how to respond to duplicate arguments
# since the simple case would generally not allow duplicate args, 
# and since duplicate args require more advanced handling,
# the default response to duplicate args is "Die".
# To allow duplicate args, the user must understand the package enough
# to set this to "Accumulate"
# Die, Warn, Ignore, Replace, Accumulate
################################################################################
sub EasyArgs_Duplicate
################################################################################
{
	my $obj = shift;
	my $type = shift;

	unless
	(
		exists($obj->{EasyArgs_ArgConfig}->{$type}->{Duplicate})
	and	defined($obj->{EasyArgs_ArgConfig}->{$type}->{Duplicate})
	)
		{
		$obj->{EasyArgs_ArgConfig}->{$type}->{Duplicate}='Die';
		}
	$obj->{EasyArgs_ArgConfig}->{$type}->{Duplicate}=$_[0] if(scalar(@_));
	return $obj->{EasyArgs_ArgConfig}->{$type}->{Duplicate};
}




################################################################################
# define how each argument takes an assignment (if at all)
# None means the arg is simply a switch, such as -v for verbose
# Equal means the arg takes an assignment with an '=' sign
# Next means the arg takes its assignment value from the next argument
# an integer (N) means the arg takes its assignment from N following args.
# Lazy means try to Do What I Mean, if command line has an '=', take it as
# an assignment, if it doesn't, allow that too. 
# Lazy, None, Equal, Next, or [integer]
################################################################################
sub EasyArgs_Assignment
################################################################################
{
	my $obj = shift;
	my $type = shift;

	unless
	(
		exists($obj->{EasyArgs_ArgConfig}->{$type}->{Assignment})
	and	defined($obj->{EasyArgs_ArgConfig}->{$type}->{Assignment})
	)
		{
		$obj->{EasyArgs_ArgConfig}->{$type}->{Assignment}='Lazy';
		}
	$obj->{EasyArgs_ArgConfig}->{$type}->{Assignment}=$_[0] if(scalar(@_));
	return $obj->{EasyArgs_ArgConfig}->{$type}->{Assignment};
}

################################################################################
# given an argument type, return whether or not a default value is given
# for the assignment of that argument.
# if a default value is given for an arg that has an assignment of Equal,
# then it is possible to put that argument on the command line without
# an actual equal sign and assignment value. The argument will instead
# recieve its default value.
################################################################################
sub EasyArgs_DefaultDefined
################################################################################
{
	my $obj = shift;
	my $type = shift;

	my $ret = exists($obj->{EasyArgs_ArgConfig}->{$type}->{Default});
	return $ret;
}


################################################################################
# given an argument type, return its default assignment value.
################################################################################
sub EasyArgs_DefaultValue
################################################################################
{
	my $obj = shift;
	my $type = shift;

	unless
	(
		exists($obj->{EasyArgs_ArgConfig}->{$type}->{Default})
	and	defined($obj->{EasyArgs_ArgConfig}->{$type}->{Default})
	)
		{
		croak "ERROR (987): called EasyArgs_DefaultValue on a type $type) "
				."with no Default value ";
		}

	if(scalar(@_))
		{
		my $val = shift(@_);
	
		if(defined($val))
			{
			$obj->{EasyArgs_ArgConfig}->{$type}->{Default}=$val;
			}
		else
			{
			delete($obj->{EasyArgs_ArgConfig}->{$type}->{Default});;
			}
		}
		
	return $obj->{EasyArgs_ArgConfig}->{$type}->{Default};
}



################################################################################
# a reference to an array of arguments.
# the array gets emptied out.
# \@ARGV, or [ @arguments ], or \@args, etc
# If the user doesn't set this to anything, then use a reference to @ARGV
# this will empty out @ARGV as the arguments are parsed.
################################################################################
sub EasyArgs_UnslurpedArgsRef
################################################################################
{
	my $obj=shift(@_);
	unless	
	(
		exists($obj->{EasyArgs_UnslurpedArgsRef})
	and	defined($obj->{EasyArgs_UnslurpedArgsRef})
	)
		{
		$obj->{EasyArgs_UnslurpedArgsRef}=\@ARGV;
		}
	$obj->{EasyArgs_UnslurpedArgsRef}=$_[0] if scalar(@_);
	return $obj->{EasyArgs_UnslurpedArgsRef};
}


################################################################################
# if in scalar context, return a reference to array of filenames
# if in list context, return list of filenames
################################################################################
sub EasyArgs_Files
################################################################################
{
	my $obj=shift(@_);
	unless	
	(
		exists($obj->{EasyArgs_FileCache})
	and	defined($obj->{EasyArgs_FileCache})
	)
		{
		$obj->{EasyArgs_FileCache}=[];
		}

	if(wantarray)
		{
		return ( @{$obj->{EasyArgs_FileCache}} );
		}
	else
		{
		return $obj->{EasyArgs_FileCache};
		}
	
}


################################################################################
# take a look at the next argument to be parsed in the unslurped array.
# if it needs to be atomized, then atomize it and push the results back
# into the array.
################################################################################
sub EasyArgs_Atomizer
################################################################################
{
	my ($obj)=@_;

	my $regexp = $obj->EasyArgs_AtomizeRegexp;
	return unless ( $obj->EasyArgs_UnslurpedArgsRef->[0] =~ /$regexp/ );

	my $arg=shift(@{$obj->{EasyArgs_UnclaimedArgs}});
	my $molecule = $arg;
	$arg=~s/^([^\w]+)//;
	my $leader = $1;

	$arg=~s/(\=.*)//;
	my $assignment = $1;

	my @switches = split(//, $arg);

	my @switch_consumes_next;
	my @final_switches;
	foreach my $swt (@switches)
		{
		my $prfx_swt = $leader . $swt;
		if($obj->EasyArgs_AssignmentCapability($prfx_swt) eq 'Next')
			{
			if(defined($assignment))
				{
				die "Error (432): switch ($prfx_swt) in molecule".
					" '$molecule' consumes next arg while molecule".
					" has an '=' assignment.";
				}
			push(@switch_consumes_next, $prfx_swt);
			}
		elsif($obj->EasyArgs_AssignmentCapability($prfx_swt) eq 'None')
			{
			if(defined($assignment))
				{
				die "Error (543): switch ($prfx_swt) in molecule".
					" '$molecule' takes no assignment while molecule".
					" has an '=' assignment.";
				}
			push(@final_switches, $prfx_swt);
			}

		elsif($obj->EasyArgs_AssignmentCapability($prfx_swt)eq 'Equal')
			{
			unless(defined($assignment))
				{
				die "Error (654): switch ($prfx_swt) in molecule".
					" '$molecule' takes an assignment but molecule".
					" has no '=' assignment.";
				}
			push(@final_switches, $prfx_swt.$assignment);
			}
		else
			{

			my $cap = $obj->EasyArgs_AssignmentCapability($prfx_swt);
			die "Error (765): Illegal value '$cap' for ".
				"EasyArgs_AssignmentCapability. Must be None,".
				"Equal or Next";


			}
		}

	if(scalar(@switch_consumes_next)>1)
		{
		my $string = join(',', @switch_consumes_next);
		die ("Error (876): multiple arguments ($string) in"
			. " molecule '$molecule' consume next arg");
		}

	push(@final_switches, @switch_consumes_next);
	unshift(@{$obj->{EasyArgs_UnclaimedArgs}}, @final_switches)
	
}


################################################################################
# given a type and arg, perform any error reporting.
# this is most likely to be used when Undefined arguments get
# a Response of "Die" or "Warn".
################################################################################
sub EasyArgs_RespondToTypeArgCombo
################################################################################
{
	my ($obj, $type, $arg) = @_;

	############################################################
	# get response for this type and respond accordingly
	############################################################
	my $response = $obj->EasyArgs_Response($type);

	if($response eq 'Die')
		{
		croak "ERROR (123): argument $arg is invalid";
		}
	elsif($response eq 'Warn')
		{
		carp "Warning (456): argument $arg is invalid";
		}
	elsif($response eq 'Silent')
		{
	
		}
	else
		{
		croak "ERROR (789): argument response '$response' for '$arg' "
			."(type '$arg') is invalid";
		}
}

################################################################################
# given a type/arg pair, 
# figure out the destination/key/value triplet.
#
# destination is a string that becomes a key into the object hash.
# these keys become a cache of the current arguments.
# There are three possible destinations, 
#  1) a cache for arguments with associated value assignments
#  2) a cache for args with no values
#  3) a cache for filenames
# 
# The key/value is the argument broken down into its root switch
# versus its assigned value.  -alt=3000 would give a key/value of
# '-alt' / '3000'
################################################################################
sub EasyArgs_AssignDestKeyVal
################################################################################
{
	my ($obj, $type, $arg) = @_;

	############################################################
	# get assignment style and assign accordingly
	############################################################
	# None, Equal, Next, or [integer]
	my $assign = $obj->EasyArgs_Assignment($type);

	my ($destination,$key,$val);

	if($type eq 'File')
		{
		$destination = 'EasyArgs_FileCache';
		$key = $arg;
		$val = 1;
		return ($destination,$key,$val);
		}

	if($assign eq 'Lazy')
		{
		# if arg has a '=', take it as an assignment
		# else, assume it is a simple switch.
		if ($arg =~ /\=/)
			{
			$assign = 'Equal';
			}
		else
			{
			$assign = 'None';
			}
	
		}


	if($assign eq 'None')
		{
		die "ERROR (234): argument '$arg' cannot accept '=' assignment"
			if ($arg =~ /\=/);

		$destination = 'EasyArgs_NoValueCache';
		$key = $arg;
		$val = 1;
		}

	elsif($assign eq 'Equal')
		{
		if($arg =~ /\=/)
			{
			($key,$val) = split(/\=/, $arg, 2);
			$destination = 'EasyArgs_ValueCache';
			}	
		elsif( $obj->EasyArgs_DefaultDefined($type) )
			{
			$key=$arg;
			$val = $obj->EasyArgs_DefaultValue($type);
			$destination = 'EasyArgs_ValueCache';
			}
		else
			{
			die "ERROR (567): argument '$arg' must contain an '=' "
				. "assigned value";
			}
		}

	elsif($assign eq 'Next')
		{
		$key=$arg;
		$val = shift(@{$obj->EasyArgs_UnslurpedArgsRef});
		$destination = 'EasyArgs_ValueCache';
		}

	elsif($assign =~ /^\d+$/)
		{
		my @arguments = splice
			(
			@{$obj->EasyArgs_UnslurpedArgsRef},
			0,
			$assign
			);

		$key=$arg;
		$val = [@arguments];
		$destination = 'EasyArgs_ValueCache';
		}

	return ($destination,$key,$val);
}

################################################################################
# given the type, argument, destination, key, and value,
# perform all the operations needed to cache the key/value into the destination.
# The tricky part comes if the argument allows more than one occurrence.
# In that case, this method must accumulate the assigned values.
#
# also, separately, if the type is of type 'File', then accumulate the filenames
# in the order they occurred on the command line.
################################################################################
sub EasyArgs_PerformDestKeyValAssignment
################################################################################
{
	my ($obj, $type, $arg, $destination, $key, $val) = @_;

	########################################################
	# have destination,key,value triplet
	# check if switch was already used, report if needed.
	# and then figure out accumulated args, replaced args, etc.
	########################################################

	# Die, Warn, Ignore, Replace, Accumulate
	my $duplicate = $obj->EasyArgs_Duplicate($type);		

	
	##########################################################
	# handle files separately from switches.	
	##########################################################
#	warn "DEBUG: you were working here.";
	if($type eq 'File')
		{
		my $arr_ref_of_files = $obj->EasyArgs_Files;
		push(@$arr_ref_of_files, $arg);
		return;
		} 

	##########################################################
	# if this arg hasn't been encountered yet,
	# the only thing you have to test for is whether
	# or not to accumuate. If accumulate, start in an anon array.
	##########################################################
	unless(exists($obj->{$destination}->{key}))
		{
		if($duplicate eq 'Accumulate')
			{
			$obj->{$destination}->{$key}=[$val];
			}
		else		
			{
			$obj->{$destination}->{$key}=$val;
			}

		return;
		}

	##########################################################
	# This is a duplicate arg, handle depending on Duplicate value
	##########################################################
	if($duplicate eq 'Die')
		{
		die "ERROR (890): duplicate argument '$arg'";
		}

	elsif($duplicate eq 'Warn')
		{
		warn "Warning (321): duplicate argument '$arg' ignored";
		}
	elsif($duplicate eq 'Ignore')
		{
		# silently ignore
		}
	elsif($duplicate eq 'Replace')
		{
		# new argument value replaces old value
		$obj->{$destination}->{$key}=$val;
		}
	elsif($duplicate eq 'Accumulate')
		{
		# push it onto existing array
		push(@{$obj->{$destination}->{$key}}, $val);
		}
}


###############################################################################
###############################################################################
###############################################################################

my %import_info;

###############################################################################
###############################################################################
###############################################################################



###############################################################################
sub merge_hashes
###############################################################################
{
	my ($dst,$src)=@_;	# input two hash references

	my @srckeys = keys(%$src);

	foreach my $srckey (@srckeys)
		{
		my $srcdata = $src->{$srckey};

		if(ref($srcdata) eq 'HASH')
			{
			unless(exists($dst->{$srckey}))
					{     $dst->{$srckey}={};    }

			merge_hashes($dst->{$srckey}, $src->{$srckey});
			}
		else
			{
			$dst->{$srckey} = $srcdata;
			}
		}
}
###############################################################################

my %recursed_hash;

sub EasyArgs_GetIsaRecursive
{
	my $pkg=shift(@_);

# 	warn "pkg is $pkg";

	$recursed_hash{$pkg}=1;

	our @list;

	my $str = '@list = @'.$pkg.'::ISA;';

	eval($str);

	foreach my $isa (@list)
		{
		next if (exists($recursed_hash{$isa}));
		EasyArgs_GetIsaRecursive($isa);
		}
}



sub EasyArgs_GetBaseArgs
{
	my $inv=shift(@_);
	my $pkg = ref($inv) || $inv;

	%recursed_hash=();

	EasyArgs_GetIsaRecursive($pkg);

	my @pkgs=keys(%recursed_hash);

	my $args_ref = {};

	foreach my $isapkg (@pkgs)
		{
		next unless(exists($import_info{$isapkg}));
		my $href = $import_info{$isapkg};
		merge_hashes($args_ref, $href);
		}

	return (%$args_ref);
}

###############################################################################
# object constructor for a single level of arguments.
###############################################################################
sub EasyArgs_New
###############################################################################
{
	my $inv=shift(@_);
	my $pkg = ref($inv) || $inv;

	my %parms = $pkg->EasyArgs_GetBaseArgs;

	my %sub_parms = ( @_ );

	merge_hashes(\%parms, \%sub_parms);

	# print Dumper \%import_info;

	my $obj;


	my $is_easy = $pkg->isa('EasyArgs');

	my $return_type = 
		defined(wantarray) ? 
			( wantarray ? 'array' : 'scalar' )
		: 'void';
	
	##############################################################
	# if the constructor was called with an object as its invocant
	# and no return value was asked for, then construct the level
	# into the current object.
	#
	# if a return value is asked for, then create a new object and
	# return that.
	##############################################################
	if( ($is_easy) and ($return_type eq 'void') )
		{
		# die unless the invocant is an object
		croak "Error (654): invocant must be object" unless(ref($inv));

		$obj=$inv; #else use the invocant as the object

		while( my($key,$val) = each (%parms) )
			{
			$obj->{$key} = $val;
			}
		}

	else	# create a new object and return that.
		{
		$obj={@_};
		bless ($obj, $pkg);
		}

	my $separator_regexp = $obj->EasyArgs_SeparatorRegexp;
	my $unslurpedargref = $obj->EasyArgs_UnslurpedArgsRef;
	while	( 
		    ( scalar(@{$unslurpedargref}) )
		and ( ($unslurpedargref->[0]) !~ /$separator_regexp/ )
		)
		{
		$obj->EasyArgs_Atomizer;

		my $arg = shift(@{$unslurpedargref});

		my $type = $obj->EasyArgs_Typify($arg);

		$obj->EasyArgs_RespondToTypeArgCombo($type, $arg);

		my ($destination,$key,$val) = 
			$obj->EasyArgs_AssignDestKeyVal($type, $arg);

		$obj->EasyArgs_PerformDestKeyValAssignment
			($type, $arg, $destination, $key, $val);

		}

	if ( scalar(@{$unslurpedargref}) )
		{
		if( ($unslurpedargref->[0]) =~ /$separator_regexp/ )
			{
			my $sep = shift(@{$unslurpedargref});
			$obj->EasyArgs_SeparatorValue($sep);
			}
		}

	return $obj;
}


###############################################################################
sub import
###############################################################################
{
	my $pkg = shift(@_);

	my @call = caller(1);

	#print Dumper \@call;

	#print Dumper \@_;

	my $calling_pkg = $call[3];
	$calling_pkg=~ s/\:\:BEGIN//;

	$import_info{$calling_pkg} = { @_ };

	#warn "in 'import' method for EasyArgs";

	#warn "\tpkg is $pkg";

	#print "\t".Dumper \@_;

	1;
}

###############################################################################
###############################################################################
###############################################################################
# package EasyArgs;
###############################################################################
###############################################################################
###############################################################################

# use base 'EasyArgs::SingleArgumentLevel';

###############################################################################
sub EasyArgs_Exists
###############################################################################
{
	my $obj=shift(@_);
	my $arg=shift(@_);

	return 1 if(exists($obj->{EasyArgs_NoValueCache}->{$arg}));

	return 1 if(exists($obj->{EasyArgs_ValueCache}->{$arg}));

}


###############################################################################
sub EasyArgs_Value
###############################################################################
{
	my $obj=shift(@_);
	my $arg=shift(@_);

	croak "Error: argument $arg does not exist"
		unless(exists($obj->{EasyArgs_ValueCache}->{$arg}));

	return $obj->{EasyArgs_ValueCache}->{$arg};
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


=cut


