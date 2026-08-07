#!/usr/bin/env bash

# Jared Still
# jkstill@gmail.com
# 2017-07-20

# asp - another sar processor
# asp-improved: simplified handling of Linux 7/8 + bundled sadf-12.4.5

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

# Linux 7/8 native sadf does not resolve disk device names properly - that was
# fixed in sysstat 12.4.0. When the bundled sadf-12.4.5 binary is present in this
# script's directory, use it for every sar file; sar data from Linux 7 also needs
# a one-time format conversion (via that same binary) before sadf-12.4.5 can read it.
scriptHome=$(dirname -- "$( realpath -s -- "$0"; )")
sadfName="sadf-12.4.5"
sadfBin="$scriptHome/$sadfName"

if [[ -x "$sadfBin" ]]; then
	usingCustomSadf=1
else
	usingCustomSadf=0
	sadfBin=$(command -v sadf)
	if [[ ${linuxInfo[version]} =~ ^(7|8)$ ]]; then
		echo
		echo "  !!! WARNING !!!"
		echo "  $sadfName binary not found in $scriptHome"
		echo "  sar disk IO files from version 7 or 8 will not include device names"
		echo
	fi
fi

echo "sadf binary: $sadfBin"

declare -A sarDestOptions

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

# sadf 12.4.5 can be used directly on sar files on Linux 8.
# However it will not work with sar files from Linux 7.
# The files on Linux 7 can be converted via 'sadf -c'.

convertSar7to8 () {
	declare sar7File=$1
	declare sar8File=$2

	[[ -r $sar7File ]] || { echo "convertSar7to8: cannot read $sar7File" >&2; return 1; }
	[[ -w $(dirname $sar8File) ]] || { echo "convertSar7to8: cannot write to $(dirname $sar8File)" >&2; return 1; }

	$sadfBin -c -- "$sar7File" > "$sar8File"
	return $?
}

tmpDir=/tmp/sar-tools
mkdir -p "$tmpDir" 2>/dev/null

declare -a tmpFiles=()
cleanupTmpFiles () {
	[[ ${#tmpFiles[@]} -gt 0 ]] && rm -f "${tmpFiles[@]}" 2>/dev/null
}
trap cleanupTmpFiles EXIT

# Prepares a sar source file for use with sadfBin: decompresses it if needed,
# and converts Linux 7 format to Linux 8 format when required.
# Sets the global $preparedFile to a plain, sadf-readable file (rather than
# echoing it - this must run in the parent shell, not a $(...) subshell, or
# the tmpFiles it registers for cleanup would vanish with the subshell).
# Called once per source file (not once per sar option), so decompression/
# conversion never repeats.
preparedFile=''
prepareSadfInput () {
	local srcFile=$1
	local workFile=$srcFile
	local fileType
	fileType=$(file "$srcFile" | awk '{print $2}' | tr '[A-Z]' '[a-z]')

	if [[ $fileType != 'data' ]]; then
		local ext=${srcFile##*.}
		local zipperExe=${zippers[$ext]:-}
		if [[ -z $zipperExe ]] || ! command -v "$zipperExe" >/dev/null 2>&1; then
			echo "prepareSadfInput: no zip program available for '$srcFile' (ext: $ext)" >&2
			return 1
		fi
		local decompressed
		decompressed=$(mktemp -p "$tmpDir" sar-decomp.XXXXXXXX)
		tmpFiles+=("$decompressed")
		"$zipperExe" $unzipOptions "$srcFile" > "$decompressed"
		workFile=$decompressed
	fi

	if [[ ${linuxInfo['version']} == '7' && $usingCustomSadf -eq 1 ]]; then
		local converted
		converted=$(mktemp -p "$tmpDir" sar8.XXXXXXXX)
		tmpFiles+=("$converted")
		if ! convertSar7to8 "$workFile" "$converted"; then
			echo "prepareSadfInput: failed to convert $workFile to Linux 8 format" >&2
			return 1
		fi
		workFile=$converted
	fi

	preparedFile=$workFile
}

set +u
# find and ls used to get the (up to) 30 most recent sar files, oldest first
declare -A csvInitialized=()

for sarFile in $(find ${linuxInfo['directory']} -type f \( -name "sa??" -o -name "sa??.*" -o -name "sa????????" -o -name "sa????????.*" \) | xargs ls -1dtar | tail -30)
do

	echo "Processing File: $sarFile"

	preparedFile=''
	if ! prepareSadfInput "$sarFile" || [[ -z $preparedFile ]]; then
		echo "  skipping $sarFile - could not prepare it for sadf"
		continue
	fi

	for saropt in "${!sarDestOptions[@]}"
	do

		csvOutputFile="${sarDstDir}/${sarDestOptions["$saropt"]}"

		if [[ -z "${csvInitialized[$saropt]:-}" ]]; then
			# first successful file for this option: keep the header row (line 1),
			# strip its leading '# ', drop any LINUX-RESTART rows
			CMD="$sadfBin -d -- $saropt $preparedFile | grep -Ev 'LINUX-RESTART' | sed -e '1s/^# //' -e 's/;/,/g' > $csvOutputFile"
		else
			# header already written: drop any header/comment or LINUX-RESTART rows
			CMD="$sadfBin -d -- $saropt $preparedFile | grep -Ev '^#|LINUX-RESTART' | sed -e 's/;/,/g' >> $csvOutputFile"
		fi

		echo "CMD: $CMD"

		if [ "$dryRun" == 'N' ]; then
			eval $CMD
			rc=$?

			# 141 == SIGPIPE - can occur when a downstream reader closes early
			# https://stackoverflow.com/questions/19120263/why-exit-code-141-with-grep-q
			if [ "$rc" -ne 141 -a "$rc" -ne 0 ]; then
				if [[ -z "${csvInitialized[$saropt]:-}" ]]; then
					echo
					echo "  !!! This Metric Not Supported !!!"
					echo "  removing ' $csvOutputFile ' from output"
					echo "  CMD: $CMD"
					echo
					rm -f $csvOutputFile 2>/dev/null
					unset 'sarDestOptions[$saropt]'
				else
					echo
					echo "  !!! CMD Failed (rc=$rc) !!!"
					echo "  CMD: $CMD"
					echo
				fi
				continue
			fi

			csvInitialized[$saropt]=1
		fi

	done

done
set -u

echo
echo Processing complete
echo
echo files located in $sarDstDir
echo

# show the files created
ls -ld ${sarDstDir}/*.csv 2>/dev/null
