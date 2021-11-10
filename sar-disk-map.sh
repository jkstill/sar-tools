#!/usr/bin/env bash

# get the major:minor for the disk device, not partions
# as that is what is recorded in sar
# generate sed commands to fixup the data
# for use without the '-p' pretty print option in asp.sh
#

sarFixupFile=sar-disk-fixup.txt

# works with ASMLib disks

for asmdisk in /dev/disk/by-label/*
do
	deviceID=$(lsblk -lnis $(readlink -f "$asmdisk" ) | tail -1 | awk '{ print $2 }')
	#echo ID: $deviceID
	major=$(echo $deviceID | cut -f1 -d:)
	minor=$(echo $deviceID | cut -f2 -d:)
	#echo "major:  $major   minor: $minor"
	sarDevice="dev${major}-${minor}"
	#echo -n $sarDevice,
	echo "s/,${sarDevice},/",$(echo $asmdisk|cut -f5 -d\/),"/g"
done | tee $sarFixupFile

cat <<-EOF

 Use the $sarFixupFile to fixup the device names in sar-csv/sar-disk.csv

 sed --file=$sarFixupFile -i.bak sar-csv/sar-disk.csv

EOF
