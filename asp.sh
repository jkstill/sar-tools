#!/usr/bin/env bash

# Jared Still
# jkstill@gmail.com
# 2017-07-20

# asp - another sar processor

# tested on:
# RedHat/Oracle  5,6,7,8
# also tested on Linux Mint

# do not use pipefail
# it causes SIGPIPE when uncompressing in a pipeline
set -u #o pipefail

help() {

	cat <<-EOF

	  $0 
       -d dest-dir 
       -p pretty print Disk Device Names
       -n no disk metrics
       -y dry run
	
	  Note: only use -p if running on the same system where sar files are generated
	  otherwise the names printed will be incorrect         	
	EOF
	
	echo
}

# returns 'releaseType:version:sar data dir:sadc version'

getLinuxVariantInfo () {
	
	local variant
	local version
	local sysstatVersion
	local releaseFile
	local oldSchool=N
	local sysstatFile

	# sysstat 10 and less use -R for memory
	# sysstat 11+ use -r for memory

	if [[ -r /etc/os-release ]]; then
		releaseFile=/etc/os-release
		variant=$(grep -E '^ID=' /etc/os-release| tr -d '[ \"]' | cut -f1 -d\. | cut -f2 -d=)
	elif [[ -r /etc/oracle-release ]]; then # old oracle - LT version 6 
		releaseFile=/etc/oracle-release
		variant='oracle'
		oldSchool=Y
		sysstatFile=/etc/sysconfig/sysstat
	elif [[ -r /etc/redhat-release ]]; then # old redhat - LT version 6 
		releaseFile=/etc/redhat-release
		variant='redhat'
		oldSchool=Y
		sysstatFile=/etc/sysconfig/sysstat
	else 
		echo 'Cannot find a suitable release file to determine Linux variant'
		return 1
	fi

	[[ -r $releaseFile ]] || { echo "failed to get release file in getLinuxVariantInfo"; exit 1; }

	# get major version number
	if [[ $oldSchool == 'Y' ]]; then
		version=$(grep -v '^\s*#' $releaseFile | head -1 | awk '{ print $NF }')
	else
		#version=$(grep -E '^VERSION=' /etc/os-release| tr -d \" | cut -f1 -d\. | cut -f2 -d=)
		# tr stripping quotes and alpha - ubuntu has alpha characters after the version
		version=$(grep -E '^VERSION=' /etc/os-release| tr -d ' \"[[:alpha:]()]+' | cut -f1 -d\. | cut -f2 -d=)
	fi

	[[ -z $version ]] && { echo "failed to get version in getLinuxVariantInfo"; exit 1; }
	[[ -z $variant ]] && { echo "failed to get variant in getLinuxVariantInfo"; exit 1; }

   # variants
	# rhel: redhat
	# fedora: redhat
	# ol: oracle 
	# linuxmint: debian
	# ubuntu: debian

	local releaseType
	if [[ $variant == 'rhel' ]]; then releaseType='redhat'
	elif [[ $variant == 'fedora' ]]; then releaseType='redhat'
	elif [[ $variant == 'ol' ]]; then releaseType='redhat'
	elif [[ $variant == 'oracle' ]]; then releaseType='redhat'
	elif [[ $variant == 'linuxmint' ]]; then releaseType='debian'
	elif [[ $variant == 'ubuntu' ]]; then releaseType='debian'
	elif [[ $variant == 'debian' ]]; then releaseType='debian'
	else releaseType='unknown'
	fi

	#echo "releaseType: $releaseType" >&2

	# 64 bit linux is assumed
	# old versions of sadc send version to stderr
	if [[ $releaseType == 'redhat' ]]; then
		sysstatVersion=$(/usr/lib64/sa/sadc -V 2>&1 | head -1 | awk '{print $NF }' | cut -d\. -f1)
		sysstatFile=/etc/sysconfig/sysstat
	else
		sysstatVersion=$(/usr/lib/sysstat/sadc -V 2>&1 | head -1 | awk '{print $NF }' | cut -d\. -f1)
		sysstatFile=/etc/sysstat/sysstat
	fi

	[[ -r $sysstatFile ]] || { echo "failed to read '$sysstatFile' in getLinuxVariantInfo"; exit 1; }

	local sarDir sarDirParm
	sarDirParm=$(grep '^SA_DIR=' $releaseFile )

	if [[ -z "$sarDirParm" ]]; then
		if [[ $releaseType == 'debian' ]]; then
			sarDir=/var/log/sysstat
		elif [[ $releaseType == 'redhat' ]]; then
			sarDir=/var/log/sa
		else
			sarDir=/var/log/sa # hope for the best
		fi
	else
		sarDir=$(echo $sarDirParm | cut -f2 -d= | tr -d '[ "]' )
	fi

	[ -x $sarDir -a -r $sarDir ] || { echo "sa log directory not found or readable"; exit 1; }

	echo "$releaseType:$version:$sarDir:$sysstatVersion"
	return 0

}

diskPrettyPrintOpts=' -j ID -p '
sarDiskOpts=''
getDiskMetrics='Y'
dryRun='N'


# variables can be set to identify multiple sets of copied sar files
sarDstDir="sar-csv"

csvConvertCmd=" sed -e 's/;/,/g' "


while getopts d:hpny arg
do
	case $arg in
		d) sarDstDir=$OPTARG;;
		p) sarDiskOpts="$diskPrettyPrintOpts";;
		n) getDiskMetrics='N';;
		y) dryRun='Y';;
		h) help; exit 0;;
		*) help; exit 1;;
	esac
done


cat << EOF

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


# though the sar files may be in 1 of 3 slightly different directory structured
# depending on version and options, we can get the most recent 30 days with find | ls
# regardless of configuration
# it is just necessary to know where the sa files are stored


declare -A linuxInfo

while IFS=: read linuxType version sarDirectory sysstatVersion
do
	linuxInfo['release']=$linuxType
	linuxInfo['version']=$version
	linuxInfo['directory']=$sarDirectory
	linuxInfo['sysstat-version']=$sysstatVersion
done < <(getLinuxVariantInfo)

echo release: ${linuxInfo[release]}
echo version: ${linuxInfo[version]}
echo directory: ${linuxInfo[directory]}
echo sysstat version: ${linuxInfo['sysstat-version']}

declare -A sarDestOptions

#sarDestOptions=( "-d ${sarDiskOpts} " '-b' '-q' '-u ALL' '-r' '-R' '-B' '-S' '-W' '-n DEV' '-n EDEV' '-n NFS' '-n NFSD' '-n SOCK' '-n IP' '-n EIP' '-n ICMP' '-n EICMP' '-n TCP' '-n ETCP' '-n UDP' '-v' '-w')

[ "$getDiskMetrics" == 'Y' ] && {
	sarDestOptions["-d ${sarDiskOpts} "]='sar-disk.csv'
}

sarDestOptions['-b']='sar-io.csv'
sarDestOptions['-q']='sar-load.csv'
sarDestOptions['-u ALL']='sar-cpu.csv'

# sysstrat 10-
# -r memory utilization
# -R memory
# sysstat 11+
# '-r ALL' memory utilization - includes the -R from older versions
# there is no -R in 11+

if [[ ${linuxInfo['sysstat-version']} -ge 11 ]]; then
	sarDestOptions['-r ALL']='sar-mem.csv'
else
	sarDestOptions['-R']='sar-mem.csv'
	sarDestOptions['-r']='sar-mem-utilization.csv'
fi

sarDestOptions['-H']='sar-hugepages-utilization.csv'
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



declare unzipOptions=' --decompress --stdout '

# [extension]=zipper
declare -A zippers=(
	[bz2]=bzip2
	[gz]=gzip
	[xz]=xz
)


#while [[ $i -lt ${#x[@]} ]]; do echo ${x[$i]}; (( i++ )); done;
# initialize files with header row

for saropt in "${!sarDestOptions[@]}"
do

	#echo "saropt: $saropt"
	#echo "file: ${sarDestOptions["$saropt"]}"

	# extra sed to remove the '^# ' in the header line
	CMD="sadf -d -- "$saropt"  | head -1 | sed -e 's/^# //' | $csvConvertCmd "

	if [ "$dryRun" == 'N' ]; then
		CMD="$CMD  > ${sarDstDir}/${sarDestOptions["$saropt"]} "
	fi
	echo CMD: $CMD

	#set -o pipefail
	eval $CMD
	rc=$?
	#set +o pipefail

	#echo "RC: $rc"
	# the following occurs due to 'set -o pipefail'
	# 141 == SIGPIPE - SIGPIPE is set by 'head -1' closing the reader while the writer (sadf) is still active
	# https://stackoverflow.com/questions/19120263/why-exit-code-141-with-grep-q
	# This does not always seem to be the case, so, checking for exit 0 as well
	if [ "$rc" -ne 141 -a "$rc" -ne 0 ]; then
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
# find and ls used to get the (up to) 30 most recent sar files
# maybe find would be better
for sarFiles in $(find ${linuxInfo['directory']} -type f \( -name "sa??" -o -name "sa??.*" -o -name "sa????????" -o -name "sa????????.*" \) | xargs ls -1dtar | tail -30)
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
			# is this a plain sar datafile, or a compressed file?
			# if compressed, which compresssion
			# can check with file or the extension
			# using both I think
			declare sadfFileType CMD
			sadfFileType=$(file $sadfFile |  awk '{ print $2 }' | tr '[A-Z]' '[a-z]' )

			echo $sadfFile type is $sadfFileType >&2

			if [[ $sadfFileType == 'data' ]]; then

				CMD="sadf -d -- $saropt $sadfFile | tail -n +2 | $csvConvertCmd  >> ${sarDstDir}/${sarDestOptions["$saropt"]} "
			else
				# get the file extension - it should match the compression program
				declare zipperExe
				zipperExe=${zippers[$(echo $sadfFile | awk -F\. '{ print $NF }' )]}
				[[ -x $(which $zipperExe) ]] || { echo "skipping file $sadfFile - zip program '$zipperExe' not found" >&2; continue; }

				# will return error 13 pipefail (RC is 141, subtract 128) if 'set -o pipefail'
				CMD="$zipperExe $unzipOptions $sadfFile | sadf -d -- $saropt | tail -n +2  | $csvConvertCmd  >> ${sarDstDir}/${sarDestOptions["$saropt"]} "

			fi

			echo DCMD: $CMD

			if [ "$dryRun" == 'N' ]; then
				eval $CMD
				declare RC=$?
				if [[ $RC -ne 0 ]]; then
					echo "#############################################"
					echo "## CMD Failed"
					echo "## $CMD"
					echo "## RC: $RC"
					echo "#############################################"
	
				fi
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

