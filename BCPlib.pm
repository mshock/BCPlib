#! perl -w

package BCPlib;

use strict;
use Pod::Usage qw(pod2usage);
use Getopt::Std qw(getopts);

my %cli_args;
getopts('hv', \%cli_args);

# only CLI function is to print usage
usage() unless caller;




# package returns The Truth
1;


####################################
#	subs
####################################

# man sub for running bcp with opts
sub bcp {
	
}

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

=head1 SEE ALSOI

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