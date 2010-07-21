package MakeChanges;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( make_changes );

use strict;
use warnings;
use lib '/home/hhofo/lib';
use Config::Std;
use Text::Diff;
$|++;

my ($fh, $contents, $change, $modified, $code, $write_change, $retval);

sub make_changes {
	my $changes = shift;	# array reference
	my $vars = shift;	# hash reference
	my $prompt = shift;	# scalar (boolean)
	my $backup = shift;	# scalar (boolean)

	foreach my $change (@$changes) {	# grab a hash reference
		$write_change = '';

		# slurp the file
		open( $fh, "< $change->{FILE}" ) or die "unable to open $change->{FILE} for reading: $!\n";
		$contents = do { local( $/ ); <$fh> };
		close $fh;

		# make the changes in $modified
		$modified = $contents;
		foreach my $ch_expr (@{ $change->{CHANGES} }) {
			$code = '$modified =~ ' . $ch_expr . ';';
			$retval = eval $code;
			die "Error in regular expression: $@\nCode: $code\n" if($@);
			print "WARNING: regex $ch_expr\ndid not match anything in $change->{FILE}.\n" if ( ! $retval );
		}

		if ( $contents ne $modified ) {
			# display a diff
			print "\nchanges to $change->{FILE}:\n";
			my $diff = diff \$contents, \$modified, { STYLE => "OldStyle" };
			print $diff;

			#prompt for changes to be written, if desired
			if ( ! defined @$prompt || ( @$prompt[0] ne "noprompt" && @$prompt[0] ne "np" )) {
				while ( $write_change eq '' ) {
					print "Do you want to make these changes (y/n)? ";
					$_ = <STDIN>;
					$write_change = 1 if /[Yy]/;
					$write_change = 0 if /[Nn]/;
				}
			} else {
				$write_change = 1;
			}

			# make a backup, if required
			if ( $backup && $write_change ) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
				$mon += 1;
				$mon = "0" . $mon if $mon < 10;
				$mday = "0" . $mday if $mday < 10;
				$year += 1900;
				my $bu_file = $change->{FILE} . '.' . $year . $mon . $mday;
				open( $fh, "> $bu_file" ) or die "unable to open $bu_file for writing: $!\n";
				print $fh $contents;
				close $fh;
			}

			# write the change back to the original file
			if ( $write_change ) {
				open( $fh, "> $change->{FILE}" ) or die "unable to open $change->{FILE} for writing: $!\n";
				print $fh $modified;
				close $fh;
			}
		} else {
			print "No changes -- $change->{FILE} is already set up with the expected changes.\n";
		}
	}
}

1;

__END__

=head1 NAME

MakeChanges.pm - Make changes to arbitrary files using perl regular expressions

 Jeff Bauman 20090401

 passed parameters are 
 an array containing hashes. The hashes contain two items: 
 the full paths of the files to be changed
 and an array of the changes to be made to the above file
 a hash containing variables to be used in the changes
 a string, typically the @ARGV array from the caller to specify whether to 
 	prompt for acceptance of each change -- either blank for  
 	prompting, or either "np" or "noprompt" if not.
 a boolean ( 1 or 0) to specifiy whether a backup of 
 	each file should be made.

