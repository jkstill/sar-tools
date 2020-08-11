#!/bin/bash

csvFile=sar-csv/sar-disk-test.csv


for operation in sum min max avg
do

	outFile=sar-csv/sar-agg-${operation}.csv

	./csv-aggregator.pl --delimiter ',' \
		--key-cols timestamp \
		--grouping-cols DEV \
		--agg-cols tps --agg-cols 'rd_sec/s' --agg-cols 'wr_sec/s' \
		--agg-operation $operation \
	< $csvFile > $outFile

done



