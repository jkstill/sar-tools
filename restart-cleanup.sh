#/usr/bin/env bash

srcDir=./csv

cd $srcDir || { echo "could not cd to '$srvDir'"; exit 1; }

for sarFile in *.csv
do
	echo working on $sarFile
	perl -n -i.bak ../restart-cleanup.pl $sarFile
done

echo
echo remove the following backup files where no longer needed
echo
ls -l *.csv.bak
echo

