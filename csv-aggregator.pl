#!/usr/bin/env perl

use strict;
use Pod::Usage;
use Data::Dumper;
# use this where available
#use Data::TreeDumper;
use Getopt::Long;

# function prototypes
sub colChk ($$$);

my %optctl = ();

my $man = 0;
my $help = 0;
## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.

my @groupingCols=();
my @aggCols=();
my @keyCols=();
my $aggOperation='sum';
my @aggValidOps=qw(sum avg min max);
my @displayCols=();
my @filterCols=();
my @filterVals=();
my $filterRegex=0;
my $searchPattern=();
my $useFilter=0;
my $printFormat="%04.6f";

GetOptions(\%optctl,
	"delimiter=s",
	"output-delimiter=s",
	"print-format=s" => \$printFormat,
	'list-available-cols!',
	"grouping-cols=s{1,10}" => \@groupingCols,
	"key-cols=s{1,10}" => \@keyCols,
	"agg-cols=s{1,10}" => \@aggCols,
	"filter-cols=s{1,}" => \@filterCols,
	"filter-vals=s{1,}" => \@filterVals,
	"filter-regex!" => \$filterRegex,
	"agg-op|agg-operation=s" => \$aggOperation,
	"debug!",
	'help|?' => \$help, man => \$man
) or pod2usage(2) ;

pod2usage(1) unless grep(/^${aggOperation}$/,@aggValidOps);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

my $listAvailableCols = defined($optctl{'list-available-cols'}) ? 1 : 0;
my $delimiter = defined($optctl{delimiter}) ? $optctl{delimiter} : ',';
my $outputDelimiter = defined($optctl{'output-delimiter'}) ? $optctl{'output-delimiter'} : ',';
my $debug = defined($optctl{debug}) ? 1 : 0;

# there should be the same number of filter values as filter columns
if ( $#filterCols != $#filterVals ) {
	print "filterCols Count: $#filterCols\n";
	print Dumper(\@filterCols);

	print "filterVals Count: $#filterVals\n";
	print Dumper(\@filterVals);
	die "\nThe number of values for --filter-cols must match the number of values for --filter-vals\n";
}

if ($filterRegex and $#filterCols) { # only 1 filtercols|filtervals allowed for regex
	die "Only 1 --filter-cols and --filter-vals allowed with --filter-regex";
}

my $hdrs=<>;
chomp $hdrs;

# if sar data there may be a leading '# ' on the header line - remove this
$hdrs =~ s/^#\s*//;

my @availDisplayCols=split(/$delimiter/,$hdrs);


if ($listAvailableCols) {
	print join("\n",@availDisplayCols),"\n";
	exit;
}


die "no grouping columns specified via --grouping-cols \n\n" unless $#groupingCols >= 0;
# aggregate columns are those for which values are additive
die "no aggregate columns specified via --agg-cols \n\n" unless $#aggCols >= 0;
die "no set columns specified via --key-cols \n\n" unless $#keyCols >= 0;

# columns that can be displayed - pretty much everything
# get this list from the first line of the CSV file
# assume the delimiter is ',' for now
# add some code later to determine the delimiter from this line
$outputDelimiter=',';

my @availGroupingCols=@availDisplayCols;
# columns that can be added
my @availAggCols=@availDisplayCols;


@displayCols = (@keyCols,@groupingCols,@aggCols);

if ($debug) {
	print "\n\@availAggCols: \n" . Dumper(\@availAggCols);
	print "\n\@availGroupingCols \n" . Dumper(\@availGroupingCols) . "\n";
	print "\n\@displayCols \n" . Dumper(\@displayCols) . "\n";
	print "\n\@groupingCols \n" . Dumper(\@groupingCols) . "\n";
	print "\n\@keyCols \n" . Dumper(\@keyCols) . "\n";
	print "\n\@groupingCols:\n" . Dumper(\@groupingCols) if $debug;
	print "\n\@aggCols \n" . Dumper(\@aggCols) . "\n";
}


# if columns used for grouping are not already in the display list, add them
my %grpColsTmp=();
my $i=0;
map {$grpColsTmp{$_}=$i++} @displayCols;

print "\n\%grpColsTmp: \n" . Dumper(\%grpColsTmp) if $debug;
print "\n\@aggCols: \n" . Dumper(\@aggCols) if $debug;

#foreach my $col ( @groupingCols ) {
#unless (defined($grpColsTmp{$col})) {
#push @displayCols,$col;
#}
#}

print "\n\@groupingCols:\n" . Dumper(\@groupingCols) if $debug;
print "\n\@displayCols:\n" . Dumper(\@displayCols) if $debug;

#exit;

# if there are any aggregate columns duplicated in the display columns,
# remove them from the display column list

foreach my $aggCol (@aggCols) {
	for (my $i=0; $i <= $#displayCols; $i++) {
		if ($aggCol eq $displayCols[$i]) {
			# neatly remove 1 element
			splice @displayCols,$i,1;
		}
	}
}

print "\n\@displayCols after pruning:\n" . Dumper(\@displayCols) if $debug;

# verify the requested column sets
colChk('Grouping Columns',\@groupingCols, \@availGroupingCols);
colChk('Aggregate Columns',\@aggCols, \@availAggCols);
colChk('Display Columns',\@displayCols, \@availDisplayCols);
colChk('Filter Columns',\@filterCols, \@availDisplayCols);

# build the search pattern
# search pattern: (?=.*(:|\b)jared\b)(?=.*(:|\b)days\b)(?=.*(:|\b)\b)
$useFilter =  ( $#filterCols >= 0 ) ? 1 : 0;

if ( $useFilter ) {

	if ($filterRegex) { # use the filter values as a regex
		$searchPattern =$filterVals[0];
	} else {

		my $searchPatternPFX='(?=.*(:|\b)';
		my $searchPatternSFX='\b)';

		foreach my $term ( @filterVals ) {
			# change spaces to underscore - this allows using \b word separator in pattern 
			$term =~ s/\s/_/g;
			$searchPattern .= "${searchPatternPFX}${term}${searchPatternSFX}{1}";
		}
	}

	warn "Search Pattern: $searchPattern\n";
}



# get list of columns with element position
my %colPos=();
$i=0;
map {$colPos{$_}=$i++} @availDisplayCols;

print "\%colPos:\n" , Dumper(\%colPos) if $debug;


# push all aggregates for a timestamp of data into a hash
# this script will not be storing all data in a hash, only a single timestamp
# then a timestamp is completed (timestamp changes), write out the data
# couple of benefits to this method
# 1. arbitrarily long files can be processed
# 2. order of timestamps is preserved without extra code.
#    the order of metrics within a timestamp is unimportant.

my %aggs=(); # aggregates
my $firstPass=1;;
my $prevKey='';


# print header line
print join($outputDelimiter,@displayCols) . ',';
print join($outputDelimiter,map{ $_ . '_' . uc($aggOperation)} @aggCols) . "\n";

#exit;

my $setCount=1;

while(<>) {

	chomp;
	my @line=split(/$delimiter/);

	if ($useFilter) {
		my @filterColPos = map { $colPos{$_} } @filterCols ;
		my @searchData = @line[ @filterColPos ];

		# die if delimiter eq space, as this just will not work then
		if ( $delimiter eq ' ') {
			die "Cannot use Filter Columns if the delimiter is a space\n";
		}

		# change data spaces to underscore
		@searchData = map { s/\s/_/g; $_  } @searchData;
		my $searchData=join(' ',@searchData);

		print '#' x 80 . "\n" if $debug;
		print "## Pattern: $searchPattern\n" if $debug;
		print "## Search Data:\n" if $debug;
		print "## $searchData\n" if $debug;
		
		if ( $searchData =~ /$searchPattern/ ) {
			;
			print "## Accepting this line\n" if $debug;
			print '## ' . join("$delimiter",@line) . "\n" if $debug;
		} else {
			print "## Rejecting this line\n" if $debug;
			print '## ' . join("$delimiter",@line) . "\n" if $debug;
			next;
		}

	}

	my @setKeys = map { $line[$colPos{$_}] } @keyCols;
	my $setKey = join(':',@setKeys);
	#print "setKey $setKey\n" if $debug;

	if ($prevKey ne $setKey) {
		if ($firstPass) {
			$firstPass=0;
		} else {
			#print "setCount: $setCount\n";
			if ($debug) {
				print '=' x 80, "\n";
				print "Set Key: $prevKey\n";
				print '%aggs: ' . Dumper(\%aggs) . "\n";;
			}
			my @keys = map{$_} keys %aggs;
			print "Keys: ", Dumper(\@keys) if $debug;

			# print the output for CSV
			foreach my $aggKey ( keys %aggs ) {
				# first the display columns (includes grouping columns)
				my $firstCol=1;
				foreach my $outCol (@displayCols) {
					print "$outputDelimiter" unless $firstCol;
					$firstCol=0 if $firstCol;
					# this will use the most recent value for the key column
					# which is probably not what is wanted
					#print "$aggs{$aggKey}->{$outCol}";

					# this will print the name of the columm, which is better for aggregates
					# it is assumed you know already what type of device is in this column
					#print "$outCol";

					# but, we do want the value of the column if it is a key column (timestamp for instance
					if ( grep(/^${outCol}$/,@keyCols ) ) {
						print "$aggs{$aggKey}->{$outCol}";
					} else {
						#print "$outCol"; # column name
						print "$aggOperation"; # whatever aggregation op is being done - sum, min, etc
					}

				}
				# and now the calculated columns
				foreach my $outCol (@aggCols) {
					print "$outputDelimiter";
					my $outVal;
					# already calculated
					if ( $aggOperation =~ /^(sum|min|max)$/ ) {
						$outVal = $aggs{$aggKey}->{$outCol};
					} elsif ($aggOperation eq 'avg' ) {
						$outVal = $aggs{$aggKey}->{$outCol} / $setCount;
					} else {
						die "Unexpected error printing output\n";
					}
					printf("$printFormat", $outVal);
				}
				print "\n";
			}

			$setCount=1;
			%aggs=();
		}
	} else { 
		$setCount++;
	}

	$prevKey=$setKey;

	my @aggKeyValues;
	map {push @aggKeyValues, $_} @groupingCols;
	print '@aggKeyValues: ' . Dumper(\@aggKeyValues) . "\n" if $debug;
	my $aggKey=join(':',@aggKeyValues);
	print "\$aggKey: $aggKey\n" if $debug;

	foreach my $displayCol (@displayCols) {
		$aggs{$aggKey}->{$displayCol} = $line[$colPos{$displayCol}];
	}

	foreach my $aggCol ( @aggCols ) {
		#print "aggCol: $aggCol\n";
		#print "aggKey: $aggKey\n";

		# iterate over each agg column in the line of data
		if ( $aggOperation =~ /^(sum|avg)$/ ) {
			$aggs{$aggKey}->{$aggCol} = 
				defined $aggs{$aggKey}->{$aggCol} 
					? $aggs{$aggKey}->{$aggCol} += $line[$colPos{$aggCol}]
					: $line[$colPos{$aggCol}];
		} elsif ( $aggOperation eq 'min' ) {
				if ( defined $aggs{$aggKey}->{$aggCol} ) {
					if ( 
						( $aggs{$aggKey}->{$aggCol} > $line[$colPos{$aggCol}] )
						&& $line[$colPos{$aggCol}] > 0
					) {
						$aggs{$aggKey}->{$aggCol} = $line[$colPos{$aggCol}];
					}
				} else {
					$aggs{$aggKey}->{$aggCol} = $line[$colPos{$aggCol}];
				}
					
		} elsif ( $aggOperation eq 'max' ) {
				if ( defined $aggs{$aggKey}->{$aggCol} ) {
					if ( $aggs{$aggKey}->{$aggCol} < $line[$colPos{$aggCol}] ) {
						$aggs{$aggKey}->{$aggCol} = $line[$colPos{$aggCol}];
					}
				} else {
					$aggs{$aggKey}->{$aggCol} = $line[$colPos{$aggCol}];
				}
					
		} else {
			die "unknown operation in calculations\n";
		}

	}

} 


# verify that all elements in first array are available in the second
# arg 1: descriptive name for error message
# arg 2: ref to array of elements to be checked
# arg 3: ref to array that contains valid elements 

sub colChk ($$$) {
	my $errName=shift;
	my $chkRef=shift;
	my $availRef=shift;

	my %availCols=();
	map {$availCols{$_}=1} @{$availRef};

	foreach my $col (@{$chkRef}) {
		unless ( defined($availCols{$col})) {
			die qq{\nColumn for "$errName" - $col is not defined in the list of valid columns\n};
		}
	}
	
}

__END__

=head1 NAME

asm-metrics-aggregator.pl

  -help brief help message
  -man  full documentation
  --key-cols list of columns that define a set of data
  --grouping-cols list of columns used as a key for aggregating additive data
  --agg-cols list of additive columns to be aggregated
  --list-available-cols just the header line of the file will be read and available columns displayed
  --delimiter input field delimiter - default is ,
  --output-delimiter output field delimiter - default is ,

 asm-metrics-aggregator.pl acts as a filter - all input is from STDIN
 As the number of columns can vary it is necessary to use the -- operator to notify
 the options processor to stop processing command line options.
 
 asm-metrics-aggregator.pl --grouping-cols DISKGROUP_NAME DISK_NAME  --agg-cols READS WRITES -- my_input_file.csv

=head1 SYNOPSIS

sample [options] [file ...]

 Options:
   --help brief help message
   --man  full documentation
   --key-cols list of columns that define a set of data
   --grouping-cols list of columns used as a key for aggregating additive data
	--print-format an sprintf() legal print format
   --agg-cols list of additive columns to be aggretated
	--agg-op or --agg-operation: 
	  aggregate operation to perform
	  valid values are: sum min max avg
	  default is 'sum'
	  note: 'min' does not report values of zero
   --list-available-cols just the header line of the file will be read and available columns displayed
	--filter-cols sar column to filter on
	--filter-vals values to filter the column specified
	--filter-regex specify this if --filter-vals is a regex
   --delimiter input field delimiter - default is ,
   --output-delimiter output field delimiter - default is ,

 asm-metrics-aggregator.pl acts as a filter - all input is from STDIN
 As the number of columns can vary it is necessary to use the -- operator to notify
 the options processor to stop processing command line options.

 asm-metrics-aggregator.pl --grouping-cols DISKGROUP_NAME DISK_NAME  --agg-cols READS WRITES -- my_input_file.csv

 output columns will be the columns specied in the --key-cols and --agg-cols arguments in the order entered

=head1 OPTIONS

=over 8

=item B<--help>

 Print a brief help message and exits.

=item B<--man>

 Prints the manual page and exits.

=item B<--list-available-cols>

 Only the header line of the file will be read and available columns displayed

=item B<--key-cols>

 List of columns that define a set of data
 Data is aggregated within this set

 example: sar data will have a time stamp. 
 you may wish to aggregate data for all disks per each timestamp

 May be repeated as often as needed.

=item B<--grouping-cols>

 List of columns that will be used to group the data for aggregation

 May be repeated as often as needed.

=item B<--agg-cols>

 List of columns that will be additively aggregated

 May be repeated as often as needed.

=item B<--agg-operation> or B<--agg-op>

 Aggregate operation to perform

 Valid values are: sum min max avg

 Default is 'sum'

 Note: 'min' does not report values of zero

=item B<--filter-cols>

 The names of the column(s) used to filter the data.

 May be repeated as often as needed

 The type of aggregation specified with --agg-operation will replace the value of the device or metric being aggregated

=item B<--print-format>

 An sprintf() legal print format.

 Default is "%04.6f"

=item B<--filter-vals>

 The values to use with column names specified in --filter-cols 

 May be repeated as often as needed.

=item B<--filter-regex>

 Treat the value in --filter-vals as a standalone regex

 Without this flag, some internal processing is performed on the value for --filter-vals

 This option may be used only with a single --filter-vals argument

 In addition, keep in mind that the regex is applied to the specified field only, not the entire line of data

 The following would be used to filter particular disk devices from a CSV file of sar disk data, getting only
 devices of major 252, minor 0-12, 14 and 17

 --delimiter ','  --key-cols timestamp --grouping-cols DEV  --agg-cols tps --agg-cols 'rd_sec/s' --agg-cols 'wr_sec/s' 
   --agg-operation sum \
	--filter-regex --filter-cols DEV --filter-vals '^dev252-([0-9]{1}?|10|11|12|14|17)$'   < sar-csv/sar-disk.csv

=item B<--list-available-cols>

 Read the header line of the input file, display the column names and exit

=item B<--delimiter>

 The character used as a delimiter between output fields for the CSV input.

=item B<--output-delimiter>

 The character used as an delimiter between output fields for the CSV output.


=back

=head1 DESCRIPTION

B<asm-metrics-aggregtor.pl> is used to aggregate a slice of the data output by B<asm-metrics-collector.pl>


=head1 EXAMPLES

 csv-aggregator.pl acts as a filter - all input is from STDIN
 As the number of columns can vary it is necessary to use the -- operator to notify
 the options processor to stop processing command line options.
 
 The grouping and aggregate columns will be added to the display list as needed.

 example: 

 Note: the default delimiter from sadf (sar) is a semi-colon

 csv-aggregator.pl --delimiter ';'  --key-cols timestamp --grouping-cols DEV --agg-cols tps --agg-cols 'rd_sec/s' --agg-cols 'wr_sec/s'  < sar-csv/sar-disk-test.csv

 2017-07-07 04:10:01 UTC,14717.25,209380.68,250210.78
 2017-07-07 04:20:01 UTC,18188.36,343755.49,340803.6
 2017-07-07 04:30:01 UTC,11496.4,388263.55,249760.5
 2017-07-07 04:40:01 UTC,13991.31,208675.61,241363.73
 2017-07-07 04:50:01 UTC,10984.36,214590.86,188312.89
 2017-07-07 05:00:01 UTC,10647.26,205521.41,183564.54
 2017-07-07 05:10:01 UTC,10568.99,248052.2,183303.25
 2017-07-07 05:20:01 UTC,10629.65,264071.7,198452.41
 2017-07-07 05:30:01 UTC,8601.38,1286509.89,253928.01
 ...


 csv-aggregator.pl  --delimiter ';'  --filter-cols DEV   --filter-vals 'DATA..' \
    --key-cols hostname --key-cols timestamp \
    --grouping-cols DEV \
    --agg-cols tps --agg-cols 'rd_sec/s' --agg-cols 'wr_sec/s'  < sar-csv/sar-disk-test.csv > sar-csv/sar-disk-test-filtered.csv

=cut


