#!/usr/bin/env bash

# Jared Still - Pythian
# still@pythian.com jkstill@gmail.com
# 2017-07-20

# asp - another sar processor

# tested on Red Hat Enterprise Linux Server release 6.6 (Santiago)
# also tested on Linux Mint

set -uo pipefail

help() {

	cat <<-EOF

	  $0 
	    -s source-dir 
	    -d dest-dir 
	    -p pretty print Disk Device Names
	
	  Note: only use -p if running on the same system where sar files are generated
	  otherwise the names printed will be incorrect         	
	EOF
	
	echo
}

diskPrettyPrintOpts=' -j ID -p '
sarDiskOpts=''


# variables can be set to identify multiple sets of copied sar files
sarSrcDir='/var/log/sa' # RedHat, CentOS ...
#sarSrcDir='/var/log/sysstat' # Debian, Ubuntu ...

sarDstDir="sar-csv"

csvConvertCmd=" sed -e 's/;/,/g' "


while getopts s:d:hp arg
do
	case $arg in
		d) sarDstDir=$OPTARG;;
		s) sarSrcDir=$OPTARG;;
		p) sarDiskOpts="$diskPrettyPrintOpts";;
		h) help; exit 0;;
		*) help; exit 1;;
	esac
done


cat << EOF

Source: $sarSrcDir
  Dest: $sarDstDir

EOF

#exit


mkdir -p $sarDstDir || {

	echo 
	echo Failed to create $sarDstDir
	echo
	exit 1

}


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
# break up network into a separate file for each option
# not all options available depending on sar version
# for disk "-d" you may want one of ID, LABEL, PATH or UUID - check the output and the sar docs
# Update for -d: if performed on a server other than the one where the sar files originated
#                the LABEL/PATH/UUID/ID will be set from the matching device on the current system
#                so the default will be to not translate device names
# The same goes for the -p option - it will take device names from the local system
# 

declare -A sarDestOptions

#sarDestOptions=( "-d ${sarDiskOpts} " '-b' '-q' '-u ALL' '-r' '-R' '-B' '-S' '-W' '-n DEV' '-n EDEV' '-n NFS' '-n NFSD' '-n SOCK' '-n IP' '-n EIP' '-n ICMP' '-n EICMP' '-n TCP' '-n ETCP' '-n UDP' '-v' '-w')

sarDestOptions["-d ${sarDiskOpts} "]='sar-disk.csv'
sarDestOptions['-b']='sar-io.csv'
sarDestOptions['-q']='sar-load.csv'
sarDestOptions['-u ALL']='sar-cpu.csv'
sarDestOptions['-r']='sar-mem-utilization.csv'
sarDestOptions['-R']='sar-mem.csv'
sarDestOptions['-B']='sar-paging.csv'
sarDestOptions['-S']='sar-swap-utilization.csv'
sarDestOptions['-W']='sar-swap-stats.csv'
sarDestOptions['-n DEV']='sar-net-dev.csv'
sarDestOptions['-n EDEV']='sar-net-ede.csv'
sarDestOptions['-n NFS']='sar-net-nfs.csv'
sarDestOptions['-n NFSD']='sar-net-nfsd.csv'
sarDestOptions['-n SOCK']='sar-net-sock.csv'
sarDestOptions['-n IP']='sar-net-ip.csv'
sarDestOptions['-n EIP']='sar-net-eip.csv'
sarDestOptions['-n ICMP']='sar-net-icmp.csv'
sarDestOptions['-n EICMP']='sar-net-eicmp.csv'
sarDestOptions['-n TCP']='sar-net-tcp.csv'
sarDestOptions['-n ETCP']='sar-net-etcp.csv'
sarDestOptions['-n UDP']='sar-net-udp.csv'
sarDestOptions['-v']='sar-kernel-fs.csv'
sarDestOptions['-w']='sar-context.csv'


#while [[ $i -lt ${#x[@]} ]]; do echo ${x[$i]}; (( i++ )); done;

# initialize files with header row

for saropt in "${!sarDestOptions[@]}"
do

	#echo "saropt: $saropt"
	#echo "file: ${sarDestOptions["$saropt"]}"

	CMD="sadf -d -- "$saropt"  | head -1 | $csvConvertCmd > ${sarDstDir}/${sarDestOptions["$saropt"]} "
	echo CMD: $CMD

	#set -o pipefail
	eval $CMD
	rc=$?
	#set +o pipefail

	#echo "RC: $rc"
	# the following occurs due to 'set -o pipefail'
	# 141 == SIGPIPE - SIGPIPE is set by 'head -1' closing the reader while the writer (sadf) is still active
	# https://stackoverflow.com/questions/19120263/why-exit-code-141-with-grep-q
	if [[ "$rc" -ne 141 ]]; then
		echo
		echo "  !!! This Metric Not Supported !!!"
		echo '  removing ' ${sarDstDir}/${sarDestOptions["$saropt"]} ' from output'
		echo "  CMD: $CMD"
		echo 
		rm -f  ${sarDstDir}/${sarDestOptions["$saropt"]}
		unset sarDestOptions["$saropt"]
	fi
	#sadf -d -- ${sarDestOptions[$i]}  | head -1 | $csvConvertCmd > ${sarDstDir}/${sarDestFiles[$i]}
	echo "################"
done

#exit

#: <<'COMMENT'

#for sarFiles in ${sarSrcDirs[$currentEl]}/sa??
set +u
for sarFiles in $(ls -1dtar ${sarSrcDir}/sa??)
do
	for sadfFile in $sarFiles
	do

		#echo CurrentEl: $currentEl
		# sadf options
		# -t is for local timestamp
		# -d : database semi-colon delimited output

		echo Processing File: $sadfFile

		for saropt in "${!sarDestOptions[@]}"
		do
			CMD="sadf -d -- $saropt $sadfFile | tail -n +2 | $csvConvertCmd  >> ${sarDstDir}/${sarDestOptions["$saropt"]} "
			echo CMD: $CMD
			eval $CMD
			if [[ $? -ne 0 ]]; then
				echo "#############################################
				echo "## CMD Failed"
				echo "## $CMD"
				echo "#############################################

			fi
			(( i++ ))
		done

	done
done


echo
echo Processing complete 
echo 
echo files located in $sarDstDir
echo 


# show the files created
i=0
while [[ $i -lt $lastSarOptEl ]]
do
	ls -ld ${sarDstDir}/${sarDestFiles[$i]} 
	(( i++ ))
done

#COMMENT

