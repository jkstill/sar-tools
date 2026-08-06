

SAR Archive Files
=================

Since 1999, sar on Linux has used this default directory structure.

`/var/log/sa`

Currently that structure is used on RedHat Linux and dirivatives.

On Debian and variants (Ubuntu, Mint,...) , sar files are probably found at `/var/log/sysstat`

## Configuration File

Debian: `/etc/sysstat/sysstat`

RedHat: `/etc/sysconfig/systat`

## Getting the Version

Debian: `/usr/lib/sysstat/sadc -V`

RedHat: `/usr/lib64/sa/sadc -V`

## Is this RedHat or Debian

## SAR files locations

### Debian

By default, the files are in `/var/log/sysstat`.

Use `grep ^SA_DIR /etc/sysstat/sysstat` if it exists.
If not, then use the default location.

### RedHat

By default, the files are in `/var/log/sa`.

Use `grep ^SA_DIR /etc/sysconfig/systat` if it exists.
If not, then use the default location.

On RedHat, the SA_DIR configuration parameter does not seem to be used prior to Linux 8.

## Archive Directory Layout

There are three different directory structures that may be used (as of 2022-05-10)

Note: it is assumed that Bash is the current shell.

```text
$ grep -h 'HISTORY=' /etc/{sysconfig,sysstat}/sysstat 2>/dev/null | cut -f2 -d= | tr -d \"
90
```

If the value returned is 28 or less, then the default directory structure will be `/var/log/sa`.

The sar files (data, not text) are `sa??`

So the files would be found as `ls -l /var/log/sa/sa??`

That is assuming of course the default directory is used (check SA_DIR in the sysstat file)

If the value is GT 28, then things begin to look different.

### sysstat version < 11.0

When HISTORY is set to 29 or more, the files will be archived by year and month in separate directories.


### sysstat version >= 11.0

### Compressed files

Additionaly, archive files may be compressed.

This value is the number of days after which files are compressed:

Note: STDERR is being discarded, as some versions of grep complain about a missing directory.
Just ensure the return value is not empty and is valid.

```text
$  grep -h 'COMPRESSAFTER=' /etc/{sysconfig,sysstat}/sysstat 2>/dev/null | cut -f2 -d= | tr -d \"
10
```

The compression program used is configured in sysstat

Ubuntu 20:
```text
grep -h 'ZIP=' /etc/{sysconfig,sysstat}/sysstat 2>/dev/null | cut -f2 -d= | tr -d \"
xz
```

Oracle Linux 7:
```text
# grep -h 'ZIP=' /etc/{sysconfig,sysstat}/sysstat 2>/dev/null | cut -f2 -d= | tr -d \"
bzip2
```

## Which Linux

Determining the platform is not always straightforward.

For several years, all major Linux distributions are using the `/etc/os-release` file.

Oracle Linux 5 does not use it.

Oracle Linux 6+ does use it.

Though we are not overly concerned with Debian/Ubuntu, any recent versions also use it.

See [/etc/os-release](http://0pointer.de/blog/projects/os-release)

And even when os-release IS used, they do not all use the same parameters.

ID_LIKE is s parameter that would easily discern between RedHat (fedora) and Debian or Ubuntu like releases.

But, not everyone uses it. So, perhaps something this will work:

```bash

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


```

## Putting this to use






