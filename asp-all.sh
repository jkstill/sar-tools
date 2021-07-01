#!/usr/bin/env bash


[[ "$#" -lt 1 ]] && {
	echo "directory basename required"
	echo example: for RAC node names ora192rac01 and ora192rac02
	echo "   asp-all.sh ora192rac0"
	exit 1
}

dirBase="$1"


for dir in ${dirBase}*
do
	echo "dir: $dir"

	echo "##############################"
	echo "## working on $dir"
	echo "##############################"

	# using -p to match disk device names may cause 
	# processing to go from 1 minute to several hours
	# for large, busy servers that have many disk devices
	./asp.sh -s "$dir"/sa -d "$dir"/csv 

done

