#!/usr/bin/env bash

# start the script from its directory
homeDir=$(pwd)

# location of scripts and python scripts, outlier-remove.py and flatten.py
# find the python scripts in https://github.com/jkstill/csv-tools

binDir=$homeDir
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
		
		# uncomment only if you have the python scripts
		#../../sar-cleaned.sh

		../../sar-chart.sh xlsx

		# uncomment only if you have the python scripts
		#../../sar-chart-cleaned.sh xlsx-cleaned

		cd $homeDir
	done
	echo "##############################################"
done

