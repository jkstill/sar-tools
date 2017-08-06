#!/bin/bash

./csv-aggregator.pl   --key-cols timestamp --grouping-cols DEV --agg-cols tps --agg-cols 'rd_sec/s' --agg-cols 'wr_sec/s'  < sar-csv/sar-disk-test.csv  
