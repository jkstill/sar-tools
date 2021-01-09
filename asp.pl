#!/usr/bin/env perl

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

Getopt::Long::GetOptions(
	\%optctl,
	"s|source-dir=s"		=> \$sourceDir,
	"d|dest-dir=s"		=> \$destDir,
	"p|pretty-print!"	=> \$prettyPrint,
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
	if ($verbose) {
		print " results: $results\n";
		print " header: $header\n";
		print "=" x 80 . "\n";
	}

	my $file = "$destDir/$sarDestOptions{$saropt}";
	my $hndl = IO::File->new("> $file") or die "could not create $file\n - $!\n";
	print $hndl "$header";

}

# process the files in date order
#

#for sarFiles in $(ls -1dtar ${sarSrcDir}/sa??)


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

  example:

  $basename --source-dir /var/log/sa --dest-disdir sar-csv --pretty-print


};
   exit $exitVal;
};

__END__



for saropt in "${!sarDestOptions[@]}"
do

	#echo "saropt: $saropt"
	#echo "file: ${sarDestOptions["$saropt"]}"

	CMD="sadf -d -- "$saropt"  | head -1 | $csvConvertCmd > ${sarDstDir}/${sarDestOptions["$saropt"]} "
	echo CMD: $CMD

	#set -o pipefail
	eval $CMD
	rc=$?
	#set +o pipefail

	#echo "RC: $rc"
	# the following occurs due to 'set -o pipefail'
	# 141 == SIGPIPE - SIGPIPE is set by 'head -1' closing the reader while the writer (sadf) is still active
	# https://stackoverflow.com/questions/19120263/why-exit-code-141-with-grep-q
	if [[ "$rc" -ne 141 ]]; then
		echo
		echo "  !!! This Metric Not Supported !!!"
		echo '  removing ' ${sarDstDir}/${sarDestOptions["$saropt"]} ' from output'
		echo "  CMD: $CMD"
		echo 
		rm -f  ${sarDstDir}/${sarDestOptions["$saropt"]}
		unset sarDestOptions["$saropt"]
	fi
	#sadf -d -- ${sarDestOptions[$i]}  | head -1 | $csvConvertCmd > ${sarDstDir}/${sarDestFiles[$i]}
	echo "################"
done

#exit

#: <<'COMMENT'

#for sarFiles in ${sarSrcDirs[$currentEl]}/sa??
set +u
for sarFiles in $(ls -1dtar ${sarSrcDir}/sa??)
do
	for sadfFile in $sarFiles
	do

		#echo CurrentEl: $currentEl
		# sadf options
		# -t is for local timestamp
		# -d : database semi-colon delimited output

		echo Processing File: $sadfFile

		for saropt in "${!sarDestOptions[@]}"
		do
			CMD="sadf -d -- $saropt $sadfFile | tail -n +2 | $csvConvertCmd  >> ${sarDstDir}/${sarDestOptions["$saropt"]} "
			echo CMD: $CMD
			eval $CMD
			if [[ $? -ne 0 ]]; then
				echo "#############################################
				echo "## CMD Failed"
				echo "## $CMD"
				echo "#############################################

			fi
			(( i++ ))
		done

	done
done


echo
echo Processing complete 
echo 
echo files located in $sarDstDir
echo 


# show the files created
i=0
while [[ $i -lt $lastSarOptEl ]]
do
	ls -ld ${sarDstDir}/${sarDestFiles[$i]} 
	(( i++ ))
done

#COMMENT

