#!/bin/bash

# moass - mother of all sar scripts

# tested on Red Hat Enterprise Linux Server release 6.6 (Santiago)

# variables can be set to identify multiple sets of copied sar files
sarMstrDir='/home/jkstill/pythian/carecentrix/sar'
sarSrcDirs=( sa )
sarDstDir="${sarMstrDir}/data/sar-csv"

# uncomment this line to use local sar files
# need cmdline options for this
#sarMstrDir='/var/log'
sarDstDir='/mnt/zips/moriarty/zips/oracle/Free-Oracle-Tools/data/sar-csv'

mkdir -p $sarDstDir || {

	echo 
	echo Failed to create $sarDstDir
	echo
	exit 1

}

lastSaDirEl=${#sarSrcDirs[@]}

echo "lastSaDirEl: $lastSaDirEl"


# sar options
# -d activity per block device
  # -j LABEL: use label for device if possible. eg. sentryoraredo01 rather than /dev/dm-3
# -b IO and transfer rates
# -q load
# -u cpu
# -r memory utilization
# -R memory
# -B paging
# -S swap space utilization
# -W swap stats
# -n network
# -v kernel filesystem stats
# -w  context switches and task creation
sarDestOptions=( '-d -j LABEL -p' '-b' '-q' '-u ALL' '-r' '-R' '-B' '-S' '-W' '-n DEV,EDEV,NFS,NFSD,SOCK,IP,EIP,ICMP,EICMP,TCP,ETCP,UDP' '-v' '-w')

sarDestFiles=( sar-disk.csv sar-io.csv sar-load.csv sar-cpu.csv sar-mem-utilization.csv sar-mem.csv sar-paging.csv sar-swap-utilization.csv sar-swap-stats.csv sar-network.csv sar-kernel-fs.csv sar-context.csv)

lastSarOptEl=${#sarDestOptions[@]}
echo "lastSarOptEl: $lastSarOptEl"

#while [[ $i -lt ${#x[@]} ]]; do echo ${x[$i]}; (( i++ )); done;

# initialize files with header row
i=0
while [[ $i -lt $lastSarOptEl ]]
do
	echo "sadf -d -- ${sarDestOptions[$i]}  | head -1 > ${sarDstDir}/${sarDestFiles[$i]} "
	sadf -d -- ${sarDestOptions[$i]}  | head -1 > ${sarDstDir}/${sarDestFiles[$i]}
	(( i++ ))
done

#exit


# process each file
currentEl=0
while [[ $currentEl -lt	 $lastSaDirEl ]]
do
	echo "Dir: ${sarSrcDirs[$currentEl]}"

	#for sarFiles in ${sarSrcDirs[$currentEl]}/sa??
	for sarFiles in $(ls -1dtar ${sarSrcDirs[$currentEl]}/sa??)
	do
		sarFiles="${sarMstrDir}/${sarFiles}"

		for sadfFile in $sarFiles
		do

			#echo CurrentEl: $currentEl
			# sadf options
			# -t is for local timestamp
			# -d : database semi-colon delimited output

			echo Processing File: $sadfFile

			i=0
			while [[ $i -lt $lastSarOptEl ]]
			do
				CMD="sadf -d -- ${sarDestOptions[$i]} $sadfFile | tail -n +2 >> ${sarDstDir}/${sarDestFiles[$i]}"
				echo CMD: $CMD
				eval $CMD
				(( i++ ))
			done

		done
	done

	(( currentEl++ ))

done

echo Processing complete 


# show the files created
i=0
while [[ $i -lt $lastSarOptEl ]]
do
	ls -ld ${sarDstDir}/${sarDestFiles[$i]} 
	(( i++ ))
done


