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

declare -A sar8TmpFiles=()
cleanupTmpFiles () {
	for saropt in "${!sar8TmpFiles[@]}"
	do
		rm -f ${sar8TmpFiles["$saropt"]} 2>/dev/null
	done
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

# if version is 7 or 8 and/or sysstat < 12.4.0 we need the sadf-12.4.5 binary to be in the same directory as asp.sh
scriptHome=$(dirname -- "$( realpath -s -- "$0"; )")

sadfName="sadf-12.4.5"

sadfBin="$scriptHome/$sadfName"
#
# is version 7 or 8 and is sadf in the same directory as asp.sh?
echo "X version: ${linuxInfo[version]}"
usingCustomSadf=1

echo "1. sadfBin: $sadfBin"

if [[ ${linuxInfo[version]} =~ ^(7|8)$ ]] && [[ ! -x "$sadfBin" ]]
then

	echo
	echo "  !!! WARNING !!!"
	echo "  $sadfName binary not found in $scriptHome"
	echo "  sar disk IO files from version 7 or 8 will not include devices names"
	echo
	sadfBin=$(which sadf)
	usingCustomSadf=0
fi

echo "2. sadf binary: $sadfBin"

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

declare -A zipOptions=(
	[bz2]=' --compress '
	[bz]=' --compress '
	[gz]=' '
	[xz]=' --compress '
)

# [extension]=zipper
declare -A zippers=(
	[bz2]=bzip2
	[bz]=bzip2
	[gz]=gzip
	[xz]=xz
)

: <<'COMMENT'

sadf 12.4.5 can be used directly on sar files on Linux 8.

However it will not work with sar files from Linux 7.

The files on Linux 7 can be converted via sadf -c

COMMENT

convertSar7to8 () {
	declare sar7File=$1
	declare sar8File=$2

	[[ -r $sar7File ]] || { echo "convertSar7to8: cannot read $sar7File"; return 1; }
	[[ -w $(dirname $sar8File) ]] || { echo "convertSar7to8: cannot write to $(dirname $sar8File)"; return 1; }

	$sadfBin -c -- "$sar7File" > "$sar8File"
	return $?
}

#while [[ $i -lt ${#x[@]} ]]; do echo ${x[$i]}; (( i++ )); done;
# initialize files with header row

oldestSarFile=$(realpath $(ls -1tr /var/log/sa/sa?? | head -1))
sar8tmpFile=$(mktemp -p /tmp/sar-tools sar8.XXXXXXXX)
sadfReferenceFile=$oldestSarFile
sadfWorkFile=$sadfReferenceFile

for saropt in "${!sarDestOptions[@]}"
do

	csvOutputFile="${sarDstDir}/${sarDestOptions["$saropt"]}"

	echo "saropt: $saropt"
	echo "file: ${sarDestOptions["$saropt"]}"
	echo "version: ${linuxInfo['version']}"
	echo "csvOutputFile: $csvOutputFile"
	echo "sadfReferenceFile: $sadfReferenceFile"

	echo ${linuxInfo['version']} 
	echo $(file $sadfReferenceFile | awk '{ print $2 }' | tr '[A-Z]' '[a-z]')

	if [[ ${linuxInfo['version']} == '7' ]] && [[ $usingCustomSadf -eq 1 ]] && [[ $(file $sadfReferenceFile | awk '{ print $2 }' | tr '[A-Z]' '[a-z]') == 'data' ]]; then

		#ls -l $sar8tmpFile

		[[ ! -s $sar8tmpFile ]] && [[ $usingCustomSadf -eq 1 ]] && {

			sar7File=$sadfReferenceFile

			echo "Converting Linux 7 sar file to Linux 8 format: $sar7File -> $sar8tmpFile"
			convertSar7to8 "$sar7File" "$sar8tmpFile"
			if [[ $? -ne 0 ]]; then
				echo "1. Failed to convert $sar7File to $sar8tmpFile"
				exit 1 
			fi
		}

		sadfWorkFile="$sar8tmpFile"
	fi

	# extra sed to remove the '^# ' in the header line
	# skip LINUX-RESTART if it exists
	CMD="$sadfBin -d -- "$saropt" $sadfWorkFile | head -10 | grep -v 'LINUX-RESTART' | head -1 | sed -e 's/^# //' | $csvConvertCmd "

	if [ "$dryRun" == 'N' ]; then
		CMD="$CMD > $csvOutputFile"
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
		echo "  removing ' $csvOutputFile ' from output"
		echo "  CMD: $CMD"
		echo 
		rm -f  $csvOutputFile 2>/dev/null
		unset sarDestOptions["$saropt"]
	fi
	#$sadfBin -d -- ${sarDestOptions[$i]}  | head -1 | $csvConvertCmd > ${sarDstDir}/${sarDestFiles[$i]}
	echo "################"

done

rm -f $sar8tmpFile 2>/dev/null

#exit

#: <<'COMMENT'

#for sarFiles in ${sarSrcDirs[$currentEl]}/sa??
set +u
# find and ls used to get the (up to) 30 most recent sar files
# maybe find would be better
for sarFiles in $(find ${linuxInfo['directory']} -type f \( -name "sa??" -o -name "sa??.*" -o -name "sa????????" -o -name "sa????????.*" \) | xargs ls -1dtar | tail -30)
do

	declare sar7File sar8File

	#trap 'echo "# $LINENO:$BASH_LINENO main() - $BASH_COMMAND";read' DEBUG

	for sadfFile in $sarFiles
	do

		sadfSourceFile=$sadfFile

		#echo CurrentEl: $currentEl
		# sadf options
		# -t is for local timestamp
		# -d : database semi-colon delimited output

		echo Processing File: $sadfFile

		# if this is a sar file from Linux 7, convert it to Linux 8 format
		# only if the sadf binary is 12.4.5 and the sar file is from Linux 7
		echo "Linux Version: ${linuxInfo['version']}"
		echo "sadf file type: $(file $sadfFile | awk '{ print $2 }' | tr '[A-Z]' '[a-z]')"

		# is this a plain sar datafile, or a compressed file?
		# if compressed, which compresssion
		# can check with file or the extension
		# using both I think
		declare sadfFileType CMD
		sadfFileType=$(file $sadfFile |  awk '{ print $2 }' | tr '[A-Z]' '[a-z]' )

		echo $sadfFile type is $sadfFileType >&2

		if [[ $sadfFileType == 'data' ]]; then

			if [[ ${linuxInfo['version']} == '7' ]] && [[ $usingCustomSadf -eq 1 ]]; then
				sar7File=$sadfFile
				sar8File=$(mktemp -p /tmp/sar-tools sar8.XXXXXXXX)
				echo "Converting Linux 7 sar file to Linux 8 format: $sar7File -> $sar8File"
				convertSar7to8 "$sar7File" "$sar8File"
				if [[ $? -ne 0 ]]; then
					echo "2. Failed to convert $sar7File to $sar8File"
					continue
				fi
				sadfFile="$sar8File"
			fi
		fi

		for saropt in "${!sarDestOptions[@]}"
		do

			if [[ $sadfFileType == 'data' ]]; then

				CMD="$sadfBin -d -- $saropt $sadfFile | grep -Ev '^#\s*hostname|LINUX-RESTART' | tail -n +2 | $csvConvertCmd  >> ${sarDstDir}/${sarDestOptions["$saropt"]} "

			else
				# get the file extension - it should match the compression program
				declare zipperExe
				zipperExe=${zippers[$(echo $sadfSourceFile | awk -F\. '{ print $NF }' )]}
				echo "sadfFile: $sadfSourceFile"
				[[ -x $(which $zipperExe) ]] || { echo "skipping file $sadfFile - zip program '$zipperExe' not found" >&2; exit 1; }

				if [[ ${linuxInfo['version']} == '7' ]] && [[ $usingCustomSadf -eq 1 ]]; then
					zipTmpFile="/tmp/sar-tools/$(basename  $sadfFile)"
					$zipperExe $unzipOptions $sadfSourceFile > $zipTmpFile

					echo "Converting Linux 7 sar file to Linux 8 format: $zipTmpFile -> $sar8File"
					convertSar7to8 "$zipTmpFile" "$sar8File"
					if [[ $? -ne 0 ]]; then
						echo "3. Failed to convert $zipTmpFile to $sar8File"
						exit 1
					fi

					$zipperExe ${zipOptions[$zipperExe]} $sar8File
					sadFile=$sar8File.$zipperExe
						
				fi

				# Currently unzipping sa files not work correctly on Linux 7 with the use of sadf-12.4.5 because the sar files are in Linux 7 format and sadf-12.4.5 does not support that format
				# will return error 13 pipefail (RC is 141, subtract 128) if 'set -o pipefail'
				CMD="$zipperExe $unzipOptions $sadfFile | $sadfBin -d -- $saropt | tail -n +2  | $csvConvertCmd  >> ${sarDstDir}/${sarDestOptions["$saropt"]} "

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

	rm -f $sar8File 2>/dev/null

done

exit

echo
echo Processing complete 
echo 
echo files located in $sarDstDir
echo 


# show the files created
ls -ld ${sarDstDir}/*.csv

cleanupTmpFiles

#COMMENT

