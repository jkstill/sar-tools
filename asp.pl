#!/usr/bin/env perl

=head1 asp.pl

 Another Sar Processor

 The sadf utility is used to dump the sa data files  to CSV output.
 (sar uses the sadf utility to read the files)

 all /var/log/sa/sa?? files are processed in timestamp order (perldoc -f stat)

 the output is a CSV file that may be directly loaded into a spreadsheet

 Jared Still
 2021-01-09 
 jkstill@gmail.com

=cut

# Copied the asp.sh bash script into this perl script, just to get the logic

use warnings;
use strict;
use FileHandle;
use Getopt::Long;
use IO::File;
use File::Path qw(make_path);
use Data::Dumper;

my %optctl = ();

my ($help) = (0);
my ($sourceDir, $destDir, $prettyPrint ) = ('','',0);
my $sarDiskOpts=' ';
my $verbose=0;
my $getDiskMetrics=1;
my $dryRun=0;

Getopt::Long::GetOptions(
	\%optctl,
	"s|source-dir=s"		=> \$sourceDir,
	"d|dest-dir=s"		=> \$destDir,
	"p|pretty-print!"	=> \$prettyPrint,
	"n|disk-metrics!"	=> \$getDiskMetrics,
	"y|dry-run!"	=> \$dryRun,
	"z|h|help"			=> \$help
);

die usage(1) unless $sourceDir && $destDir;

$sarDiskOpts = ' -j ID -p ' if $prettyPrint;

my $pathERR;
if ( ! -d $destDir ) {
	make_path($destDir, { verbose => 0, error => \$pathERR});
	if ( pathErrors($destDir, $pathERR) ) { die; }
}

print "Dest Dir: $destDir\n";

# make sure sadf and sar are both available
my @which=();
foreach my $cmd2chk ( qw{sadf sar} ) {
	my $cmdStatus = system("which $cmd2chk >/dev/null");
	#print "fpCmd: $fpCmd\n";
	if ($cmdStatus == 0) { 
		push @which,$cmd2chk;
	} else {
		die "cmd '$cmd2chk' not found\n";
	}
}

# now make sure they work
#push @which,'bogus';
foreach my $cmd2chk ( @which ) {
	my $cmdResults = qx{$cmd2chk -help 2>&1};
	if (! $cmdResults ) {
		die "Error running '$cmd2chk'\n";
	}

}

#exit;

=head1 sar options

 These options work for Linux 3.8+ kernels, and possibly earlier 3.x versions

 Some of these options do NOT work on 2.x kernels

 Modifications need to be made based on the kernel.

 I wish it were no longer necessary to accomodate 10 year old OS versions

   -d activity per block device
   -j LABEL: use label for device if possible. eg. sentryoraredo01 rather than /dev/dm-3
	-p Pretty print
   -b IO and transfer rates
   -q load
   -u cpu
   -r memory utilization
   -R memory
   -B paging
   -S swap space utilization
   -W swap stats
   -n network
   -v kernel filesystem stats
   -w context switches and task creation
      break up network into a separate file for each option
      not all options available depending on sar version

   -d Notes:
      for disk "-d" you may want one of ID, LABEL, PATH or UUID - check the output and the sar docs
      Update for -d: if performed on a server other than the one where the sar files originated
      the LABEL/PATH/UUID/ID will be set from the matching device on the current system
      so the default will be to not translate device names

   -p Notes:
      As with -d,  it will take device names from the local system
 
=cut

# options are matched to output file names
my %sarDestOptions = (
	"-d ${sarDiskOpts} "	=> 'sar-disk.csv',
	'-b'						=> 'sar-io.csv',
	'-q'						=> 'sar-load.csv',
	'-u ALL'					=> 'sar-cpu.csv',
	'-r'						=> 'sar-mem-utilization.csv',
	'-R'						=> 'sar-mem.csv',
	'-B'						=> 'sar-paging.csv',
	'-S'						=> 'sar-swap-utilization.csv',
	'-W'						=> 'sar-swap-stats.csv',
	'-n DEV' 				=> 'sar-net-dev.csv',
	'-n EDEV'				=> 'sar-net-ede.csv',
	'-n NFS'					=> 'sar-net-nfs.csv',
	'-n NFSD'				=> 'sar-net-nfsd.csv',
	'-n SOCK'				=> 'sar-net-sock.csv',
	'-n IP'					=> 'sar-net-ip.csv',
	'-n EIP'					=> 'sar-net-eip.csv',
	'-n ICMP'				=> 'sar-net-icmp.csv',
	'-n EICMP'				=> 'sar-net-eicmp.csv',
	'-n TCP'					=> 'sar-net-tcp.csv',
	'-n ETCP'				=> 'sar-net-etcp.csv',
	'-n UDP'					=> 'sar-net-udp.csv',
	'-v'						=> 'sar-kernel-fs.csv',
	'-w'						=> 'sar-context.csv',
);

print "getDiskMetrics: $getDiskMetrics\n";

if (! $getDiskMetrics ) {
	#print "Deleting Disk Metrics\n";
	delete $sarDestOptions{"-d ${sarDiskOpts} "};
}

#print '%sarDestOptions: ' . Dumper(\%sarDestOptions);

# this would be more robust with IPC::Open3
# for now, just using qx{}

=head1 Create SAR CSV file with header

 If the sar command fails due to incorrect options, that cmd is removed from the list.

 There are several options that do not work on Linux 5.x

 Sometimes the information is just not available for a particular option

=cut

my $header;
foreach my $saropt ( keys %sarDestOptions ) {

	my $CMD=qq{sadf -d -- $saropt };

	# verify the command can be executed with these options
	# complain if not, and remove the command from the hash

	my $results= qx($CMD  2>&1 | head -1);

	if ( $results =~ 'Requested activities not available' ) { 
		delete $sarDestOptions{$saropt};
		if ($verbose) {
			warn "==>> CMD Failed: $CMD\n";
			warn "$results\n";
			warn "This CMD will not be used\n";
			print "=" x 80 . "\n";
		}
		next;
	} 

	print "CMD is usable: $CMD\n";

	($header = $results) =~ s/;/,/go;
	$header =~ s/^#\s//;
	if ($verbose or $dryRun) {
		print " results: $results\n";
		print " header: $header\n";
		print "=" x 80 . "\n";
	}

	if (! $dryRun ) {
		my $file = "$destDir/$sarDestOptions{$saropt}";
		my $hndl = IO::File->new("> $file") or die "could not create $file\n - $!\n";
		print $hndl "$header";
	}

}

# process the files in date order
#

#for sarFiles in $(ls -1dtar ${sarSrcDir}/sa??)

=head1 Append SAR data to the newly created files

 Loop through the list of commands
   process each file in the list, using the current command

=cut

my @saFiles = getSAFiles($sourceDir);
#print "sa files:\n" . join("\n", @saFiles) . "\n";

foreach my $saropt ( keys %sarDestOptions ) {

	print "working on 'sar $saropt ${destDir}/$sarDestOptions{$saropt}'\n";
	my $CMD=qq{sadf -d -- $saropt };

	my $csvFile = "$destDir/$sarDestOptions{$saropt}";
	my $hndl;
	if (! $dryRun ) {
		$hndl = IO::File->new(">> $csvFile") or die "could not open $csvFile for writing\n - $!\n";
	}

	foreach my $saFile ( @saFiles ) {


		my $CMD="sadf -d -- $saropt $saFile " ; # | >> ${destDir}/$sarDestOptions{$saropt} ";

		if ($verbose or $dryRun) {
			print "CMD: $CMD\n";
		} else {
			print '.';
		}

		if (! $dryRun ) {
			my @results  = qx($CMD  2>&1 );

			my $hdr = shift @results; # just throwing away the header here

			my @output = map { my $a = $_; $a =~ s/;/,/g; $a } @results;
			print $hndl @output;
		}
	}

	print "\n";

	if (! $dryRun ) {
		close $hndl;
	}

}

=head1 an end of main marker I can see in the editor
 ###############################################################
 ###############################################################
 ###############################################################
=cut

sub getSAFiles {
	my ($sourceDir) = @_;

	# get the file list
	opendir(my $dh, $sourceDir) || die "Can't opendir $sourceDir - $!\n";
	my @saFiles = grep(/^sa[0-9]{2}/, readdir($dh));
	closedir $dh;

	if ( ! @saFiles ) {
		die "no sa files found in directory $sourceDir\n";
	}

	# now get them in date order
	# you did copy them with 'cp -p' or similar, right?
	my %workFiles;
	foreach my $saFile ( @saFiles ) {

		my $file2chk = "$sourceDir/$saFile";

		# stat returns the modified time in seconds since the epoch
		# just sort on that
		# this is pretty much guaranteed to fail if the timestamps on
		# the sa files were not preserved. 
		# such as with 'cp ' without the -p option 
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
			$atime,$mtime,$ctime,$blksize,$blocks)
			= stat($file2chk);

			#print "file: $file2chk\n";
			#print "  mtime: $mtime\n\n";

		if ( ! exists $workFiles{$mtime} ) {
			$workFiles{$mtime} = $file2chk;
		} else {
			# collision on mtime
			# message, and try up to 5 times add 1 second
			# still, no guarantee the order will be correct in the finished output
			# why 5?  arbitrary, but, this may have already been done with other files as well
			# so there could already have been some files where the timestamp was adjusted
			warn "Collision!  2 filesnames have the same timestamp\n";
			warn "Making up to 5 attempts to add 1 second to the timestamp and continue\n";

			foreach my $i ( 1..5 ) {

				if ( ! exists $workFiles{$mtime+$i} ) {
					$workFiles{$mtime+$i} = $file2chk;
					last;
				}

				if ( $i == 5 ){ die "timestamp collision on $file2chk\n"; }

			}
		}
	}

	my @saFilesSorted;
	foreach my $epochTime (  sort {$a <=> $b} keys %workFiles ) {
		#print "file: $workFiles{$epochTime}\n";
		push @saFilesSorted, $workFiles{$epochTime};
	}

	return @saFilesSorted;

}




sub pathErrors {
	my ($path, $pathErrAry)  = @_;

	if ( exists $pathErrAry->[0] ) {

		warn "\nErrors encountered with operation on Path: $path\n";

		foreach my $errHash ( @{$pathErrAry}) {
			foreach my $errKey ( keys %{$errHash} ) {
				print "-->> mkpath error: $errKey = $errHash->{$errKey}\n";
			}
		}
		print "\n";
		return 1;
	}

	return 0;
}


sub usage {
	my $exitVal = shift;
	$exitVal = 0 unless defined $exitVal;
	use File::Basename;
	my $basename = basename($0);
	print qq{

usage: $basename

  -s
  --source-dir    directory containing sar sa files (the binary files)

  -d
  --dest-dir      the directory where CSV files will be written

  -p
  --pretty-print  pretty print Disk Device Names
                  only use -p if running on the same system where sar files are generated
                  otherwise the names printed will be incorrect         	

  --disk-metrics     get disk-metrics 
  --no-disk-metrics  do not process disk-metrics 

  -y 
  --dry-run       do not process the sar files or generate output

  example:

  $basename --source-dir /var/log/sa --dest-disdir sar-csv --pretty-print


};
   exit $exitVal;
};



