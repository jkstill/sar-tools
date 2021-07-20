#!/bin/bash

csvFile=sar-csv/sar-disk-test.csv


: << 'COMMENT'

This example creates 4 new CSV files from the sar disk activity file.

  sar-csv/sar-agg-min.csv
  sar-csv/sar-agg-max.csv
  sar-csv/sar-agg-sum.csv
  sar-csv/sar-agg-avg.csv

Each file will have the min/max/sum/avg of following columns, per timestamp

       tps:  transfers per second
 red_sec/s:  sectors read per second
  wr_sec/s:  sectors written per second

COMMENT


for operation in sum min max avg
do

	outFile=sar-csv/sar-agg-${operation}.csv

	./csv-aggregator.pl --delimiter ',' \
		--key-cols timestamp \
		--grouping-cols timestamp \
		--agg-cols tps --agg-cols 'rd_sec/s' --agg-cols 'wr_sec/s' \
		--agg-operation $operation \
	< $csvFile > $outFile

done



