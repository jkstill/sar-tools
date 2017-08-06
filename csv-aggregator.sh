#!/bin/bash

csvFile=sar-csv/sar-disk-test.csv

#./csv-aggregator.pl   --key-cols timestamp --grouping-cols DEV --agg-cols tps --agg-cols 'rd_sec/s' --agg-cols 'wr_sec/s'  < $csvFile

./csv-aggregator.pl --filter-cols DEV  --filter-vals 'DATA..'  --key-cols hostname --key-cols timestamp  --grouping-cols DEV  --agg-cols tps --agg-cols 'rd_sec/s' --agg-cols 'wr_sec/s'  --agg-cols 'avgrq-sz' --agg-cols 'avgqu-sz' < $csvFile


