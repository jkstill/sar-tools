#!/usr/bin/env perl

use Data::Dumper;
use warnings;
use strict;

print qq{

 this is a test to demonstrate building a search pattern with wild cards and positive assertion lookahead

 this method will find a match in the array slice of data to search regardless of the order of the elements in the arr
 used to build the search pattern

};

# as if read from a file
my $line='test one,test two,test three,test four,test five';

my @data=split(/,/,$line);

# search values collected from data
my @searchPattern=('test two', 'test four');

# reverse it to test Positive Lookahead Assertion
@searchPattern=('test four','test two');
# try wild cards
@searchPattern=('test f..r','te.* two');

my $searchPattern=join(',',@searchPattern);

# the data to search was sliced from the data @d
my @colVals=(1,3);
my @searchData=@data[@colVals];
my $searchData=join(',',@searchData);

print '@searchPattern: ' . Dumper(\@searchPattern);
print '@searchData: ' . Dumper(\@searchData);

if ( $searchData =~ /$searchPattern/ ) {
	print "Found it!\n\n";
}

# modify data for search so we can use \b word boundary
# change spaces to underscore
@searchData = map { s/\s/_/g; $_  } @searchData;
print '@searchData: ' . Dumper(\@searchData);
$searchData=join(' ',@searchData);


$searchPattern='';
my $spPfx='(?=.*(:|\b)';
my $spSfx='\b)';

foreach my $term ( @searchPattern ) {
	# change spaces to underscore
	$term =~ s/\s/_/g;
	$searchPattern .= "${spPfx}${term}${spSfx}{1}";
}

print "\nSP2: $searchPattern\n\n";

if ( $searchData =~ /$searchPattern/ ) {
	print "Found it with Positive Lookahead Assertion!\n\n";
}


