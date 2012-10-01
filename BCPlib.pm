#! perl -w

package BCPlib;

use strict;

# allow functional access
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(bcp);

use Carp;
use Pod::Usage qw(pod2usage);
use Params::Check qw(check);
use Getopt::Std qw(getopts);

# autoload global var
our $AUTOLOAD;

my %cli_args;
getopts('hv', \%cli_args);

my $verbose = $cli_args{v};

# only CLI function is to print usage
usage() unless caller;




# package returns The Truth
1;


####################################
#	subs
####################################

# constructor
sub new {
	my ($class, $args_href) = @_;
	$class = ref($class) || $class;
	
	# database objects are hashrefs of database info
	my ($export_db, $import_db);
	
	# Params::Check template
	my $tmpl = {
		export_db => {	
			default => {},
			strict_type => 1,
			store => \$import_db,
		},
		import_db => {
			default => {},
			strict_type => 1,
			store => \$export_db,
		},	
	};
	# verify all arguments
	check($tmpl, $args_href, $verbose)
		or carp "unable to parse BCPlib constructor args\n"
		and return undef;
	
	# create hashref object
	my $self = {
		export_db => $export_db,
		import_db => $import_db,
	};
	
	# bless & return object
	bless $self, $class;
	return $self;
}


# functional interface to module
sub bcp {
	
}

# OO bcp in
sub in {
	my ($self, $args_href) = @_;
	
	# verify import database
	my $tmpl = {
		import_database => {},
	};
	check($tmpl, $args_href, $verbose)
		or die "unable to parse args\n";
	
}

# OO bcp out
sub out {
	
}

# OO bcp queryout
sub queryout {
	
}

# get/set through AUTOLOAD
sub AUTOLOAD {
	my $self = shift or return undef;
	my $func = $AUTOLOAD;
	
	# determine get/set and which variable
	if ($func =~ m/(\w+)_(\w+)/i) {
		my ($op,$attr) = ($1,$2);
		# get attribute
		if (lc $op eq 'get') {
			# add new sub to symbol table
			{
				no strict 'refs';
				*{$AUTOLOAD} = sub {return shift->{$attr}};
			}
		}
		# set attribute
		elsif (lc $op eq 'set') {
			{
				no strict 'refs';
				*{$AUTOLOAD} = sub {return shift->{$attr} = shift};
			}
		}
		else {
			carp "unsupported operation $op in AUTOLOAD\n";
			return undef;
		}
		# goto the newly created method
		goto &$AUTOLOAD;
	}
	else {
		carp "unable to parse call to $func in AUTOLOAD\n";
		return undef;
	}	
}

# avoid calling AUTOLOAD on DESTROY
sub DESTROY {};

# print usage from pod
sub usage {
	my ($verbosity) = @_;
	# verbosity defaults to 1
	$verbosity ||= 1;
	# exit with failure if help not explicitly called
	my $exit_val = $cli_args{h} || 0;
	
	pod2usage({ 
		-msg => 'BCPlib Perl Module',
		-verbose => $verbosity,
		-exitval => $exit_val,		
	});
}

__END__

=pod

=head1 NAME

BCPlib - library of functions interfacing with BCP w/ SQL focus

=head1 SYNOPSIS

	# OO interface:
	use BCPlib;
	$bcp_obj = BCPlib->new();
	# func interface
	use BCPlib qw(bcp);
	bcp($arg_href);
	
=head1 DESCRIPTION

This is a simple library interface to the BCP Windows utility.
I believe there is a need for this because Sybase(::BCP) is not included in ActiveState's Perl Package Manager (PPM)

=head1 SEE ALSO

Sybase::BCP
http://search.cpan.org/~mewp/sybperl-2.19/BCP/BCP.pm

=head1 AUTHOR

Matt Shockley <shockleyme |AT| gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright Matt Shockley 2012
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head VERSION

version 0.01

=cut