#!/usr/bin/env bash

homeDir=/mnt/zips/tmp/pythian/opentext/sow7/sar

# location of scripts and python scripts, outlier-remove.py and flatten.py
binDir=/mnt/zips/tmp/pythian/opentext/sow7/sar
export PATH="$binDir":$PATH

:<<'COMMENT'

assuming directory structure of

cluster01/
  node-01/
  node-02/
cluster02/
  node-01/
  node-02/
...

COMMENT


for cluster in cluster0* 
do
	echo "##############################################"
	echo "cluster: $cluster"
	for server in "$cluster"/"$cluster"*
	do
		echo "   ============================================"
		echo "   server: $server"
		cd $server
		# run the data cleanup for extra of charts
		
		../../sar-cleaned.sh

		../../sar-chart.sh xlsx
		../../sar-chart-cleaned.sh xlsx-cleaned
		cd $homeDir
	done
	echo "##############################################"
done

