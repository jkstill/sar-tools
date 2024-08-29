#!/usr/bin/env bash

# This script will remove all RESTART messages from the CSV file
# It will make sure only 1 header is present in the file


for csvfile in csv/*.csv; do
	 echo "Processing $csvfile"
	 # Remove all RESTART messages
	 sed -i '/RESTART/d' $csvfile
	 # find a header and save it in a variable
	 # remove all headers then prepend the saved header
	 header=$(grep -m 1 "^#" $csvfile)
	 # remove the leading # from the header
	 header=$(echo $header | sed 's/^# //')
	 sed -i '/^#/d' $csvfile
	 
	 # Add the header back to the file
	 tmpfile=$(mktemp)
	 echo "$header" > $tmpfile
	 cat $csvfile >> $tmpfile
	 mv $tmpfile $csvfile
	 echo "Done processing $csvfile"
done


