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

my $verbose = 0;

# only CLI function is to print usage
usage() unless caller;

# package returns The Truth
1;


####################################
#	subs
####################################

# constructor
sub new {
	my $class = shift;
	$class = ref($class) || $class;
	my $params = shift;
	
	# database objects are hashrefs of database info
	my ($export_db, $import_db, $bcp_path, $error_log);
	
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
		bcp_path => {
			default => '',
			strict_type => 1,
			store => \$bcp_path,
		},
		error_log => {
			default => 'bcp.errors',
			strict_type => 1,
			store => \$error_log,
		},
	};
	# verify all arguments
	check($tmpl, $params, $verbose)
		or carp "unable to parse BCPlib constructor args\n"
		and return undef;
	
	# create hashref object
	my $self = {
		export_db => $export_db,
		import_db => $import_db,
		bcp_path => $bcp_path,
		error_log => $error_log,
		last_result => undef,
	};
	
	# bless & return object
	bless $self, $class;
	return $self;
}


# functional interface to module
sub bcp {
	my $params = shift;
	
	my ($op,$db,$bcp_path,$table,$error_log,$encoding,$query_out);
	
	my $tmpl = {
		op => {
			required => 1,
			allow => qr/^(in|out|queryout)$/i,
			store => \$op,
		},
		query => {
			defined => 1,
			store => \$query_out,
		},
		db => {
			required => 1,
			defined => 1,
			store => \$db,
		},
		bcp_path => {
			required => 1,
			defined => 1,
			store => \$bcp_path,
		},
		table => {
			defined => 1,
			store => \$table,
		},
		error_log => {
			default => 'bcp.errors',
			strict_type => 1,
			store => \$error_log,
		},
		encoding => {
			default => 'c',
			strict_type => 1,
			allow => qr/^[cnNw]$/,
			store => \$encoding,
		},
	};
	check($tmpl, $params, $verbose)
		or carp "unable to parse bcp args\n"
		and return;
	
	# check that there is a query for queryout
	if ($op eq 'queryout' && !$query_out) {
		carp "no query passed for queryout in bcp";
		return;
	} 
	
	# change bcp's first argument based on operation
	my $bcp_arg = $op eq 'queryout' ? $query_out : "[$db->{name}].dbo.[$table]";
	
	# run bcp command
	return `bcp $bcp_arg $op $bcp_path -S$db->{server} -U$db->{user} -P$db->{pwd} -e$error_log -$encoding`;
}

# OO bcp in
sub in {
	my $self = shift;
	my $params = shift;
	
	my ($import_db, $table, $error_log, $encoding, $bcp_path);
	my $tmpl = {
		import_db => {
			default => $self->{import_db},
			strict_type => 1,
			store => \$import_db,
		},
		table => {
			required => 1,
			defined => 1,
			store => \$table,
		},
		error_log => {
			default => $self->{error_log},
			strict_type => 1,
			store => \$error_log,
		},
		encoding => {
			default => 'c',
			strict_type => 1,
			store => \$encoding,
		},
		bcp_path => {
			default => $self->{bcp_path},
			strict_type => 1,
			store => \$bcp_path,
		}
	};
	
	check($tmpl, $params, $verbose) 
		or carp "unable to parse bcp in params\n"
		and return undef;	
	
	# check that an import database has been added to the object
	unless ($import_db) {
		carp "no import database configured cannot bcp in\n";
		return undef;
	}
	unless ($bcp_path) {
		carp "no bcp path configured cannot bcp in\n";
		return undef;
	}

	my $cmd_db = "[$self->{import_database}->{name}].dbo.[$table]";
	
	$self->{last_result} = `bcp $cmd_db in $self->{bcp_path} -e$error_log -$encoding`;
	
	return $self;
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
	}
	else {
		carp "unable to parse call to $func in AUTOLOAD\n";
		return undef;
	}
	
	# goto the newly created method
	goto &$AUTOLOAD;
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