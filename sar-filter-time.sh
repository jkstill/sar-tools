#!/usr/bin/env bash

# This script calls sar-filter-type.py to filter the output of sar to only include data from a specific time range.
#
csvSrcDir=$1
csvDstDir=$2

# set the time range to filter by
beginTime='2026-05-10 00:55:00'
endTime='2026-05-10 01:40:00'

[[ -z "$csvSrcDir" || -z "$csvDstDir" ]] && { echo "Usage: $0 <csvSrcDir> <csvDstDir>"; exit 1; }

[[ -d "$csvSrcDir" ]] || { echo "Source directory $csvSrcDir does not exist"; exit 1; }

[[ -d "$csvDstDir" ]] || mkdir -p "$csvDstDir"

# Example usage:
# ./sar-filter-time.py csv-original/sar-hugepages-utilization.csv --begin '2026-05-10 00:55:00' --end '2026-05-10 01:32:10' --output csv-filtered/sar-hugepages-utilization.csv

for csvFile in "$csvSrcDir"/*.csv; do
	 #[[ -f "$csvFile" ]] || continue
	 dstFile="$csvDstDir/$(basename "$csvFile")"
	 echo "Filtering $csvFile to $dstFile for time range $beginTime to $endTime"
	 python3 sar-filter-time.py "$csvFile" --output "$dstFile" --begin "$beginTime" --end "$endTime"
	 echo
done

