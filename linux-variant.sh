#!/usr/bin/env bash


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

