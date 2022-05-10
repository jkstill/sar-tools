#!/usr/bin/env bash

# returns 'releaseType:version'

getLinuxVariant () {
	
	local variant
	local version
	local releaseFile
	local oldSchool=N

	if [[ -r /etc/os-release ]]; then
		releaseFile=/etc/os-release
		variant=$(grep -E '^ID=' /etc/os-release| tr -d '[ \"]' | cut -f1 -d\. | cut -f2 -d=)
	elif [[ -r /etc/oracle-release ]]; then # old oracle - LT version 6 
		releaseFile=/etc/oracle-release
		oldSchool=Y
		variant='oracle'
	elif [[ -r /etc/redhat-release ]]; then # old redhat - LT version 6 
		releaseFile=/etc/redhat-release
		variant='redhat'
		oldSchool=Y
	else 
		echo 'Cannot find a suitable release file to determine Linux variant'
		return 1
	fi

	[[ -r $releaseFile ]] || { echo "failed to get release file in getLinuxVariant"; exit 1; }

	# get major version number
	if [[ $oldSchool == 'Y' ]]; then
		version=$(grep -v '^\s*#' $releaseFile | head -1 | awk '{ print $NF }')
	else
		#version=$(grep -E '^VERSION=' /etc/os-release| tr -d \" | cut -f1 -d\. | cut -f2 -d=)
		# tr stripping quotes and alpha - ubuntu has alpha characters after the version
		version=$(grep -E '^VERSION=' /etc/os-release| tr -d ' \"[[:alpha:]()]+' | cut -f1 -d\. | cut -f2 -d=)
	fi

	[[ -z $version ]] && { echo "failed to get version in getLinuxVariant"; exit 1; }
	[[ -z $variant ]] && { echo "failed to get variant in getLinuxVariant"; exit 1; }

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

	echo "$releaseType:$version"
	return 0

}

declare -A linuxInfo

while IFS=: read linuxType version
do
	linuxInfo['release']=$linuxType
	linuxInfo['version']=$version
done < <(getLinuxVariant)

echo release: ${linuxInfo[release]}
echo version: ${linuxInfo[version]}


