#!/bin/bash

# tested on Red Hat Enterprise Linux Server release 6.6 (Santiago)

# variables can be set to identify multiple sets of copied sar files
#sarMstrDir='/mnt/zips/moriarty/zips/oracle/Free-Oracle-Tools/data/sar-2016'
#sarSrcDirs=( sar/201605 sar/201606 sar/201607 sar/201608)
#sarDstDir="${sarMstrDir}/data/sar-csv"

sarMstrDir='/var/log/sa'
sarSrcDirs='' # not needed for server source data
sarDstDir='/mnt/zips/moriarty/zips/oracle/Free-Oracle-Tools/data/sar-csv'

mkdir -p $sarDstDir

lastEl=${#sarSrcDirs[@]}

echo "LastEL: $lastEl"

diskDstFile=$sarDstDir/sar-disk.csv
sadf -d -- -d | head -1 > $diskDstFile

ioDestFile=$sarDstDir/sar-io.csv
sadf -d -- -b | head -1 > $ioDestFile

currentEl=0

while [[ $currentEl -lt	 $lastEl ]]
do
	echo "Dir: ${sarSrcDirs[$currentEl]}"

	for sarFiles in ${sarSrcDirs[$currentEl]}/sa??
	do
		sarFiles="${sarMstrDir}/${sarFiles}"

		for sadfFile in $sarFiles
		do

			#echo CurrentEl: $currentEl
			# sadf options
			# -t is for local timestamp
			# -d : database semi-colon delimited output

			# sar options
			# -d activity per block device
			# -b IO and transfer rates
			# -j LABEL: use label for device if possible. eg. sentryoraredo01 rather than /dev/dm-3
			echo Processing File: $sadfFile
			#echo "CMD: sadf -t -d $sadfFile -- -d -j LABEL	| tail -n +2 "
			#echo "CMD: sadf -t -d $sadfFile -- -b	| tail -n +2 "
			sadf -t -d $sadfFile -- -d -j LABEL	| tail -n +2 >> $diskDstFile
			sadf -t -d $sadfFile -- -b	| tail -n +2 >> $ioDestFile

		done
	done

	(( currentEl++ ))

done

echo Processing complete 

echo
echo ioDestFile: $ioDestFile
echo diskDestFile: $diskDstFile

