#!/usr/bin/env bash


srcDir=csv
destDir=csv-cleaned
mkdir -p $destDir

echo -n 'PWD: '
pwd

	echo $csvFile

#: << 'COMMENT'

	echo working on sar-network-device.csv
	outlier-remove.py   'rxkB/s'  'txkB/s' < "$srcDir"/sar-net-dev.csv \
		| flatten.py   'rxkB/s'  'txkB/s' > "$destDir"/sar-net-dev-cleaned.csv

	echo working on sar-network-error-device.csv
	outlier-remove.py   'rxerr/s'  'txerr/s' < "$srcDir"/sar-net-ede.csv \
		| flatten.py   'rxerr/s'  'txerr/s' > "$destDir"/sar-net-ede-cleaned.csv

	echo working on sar-network-nfs.csv
	outlier-remove.py   'call/s'  'retrans/s'  'read/s'  'write/s'  'access/s'  'getatt/s'  < "$srcDir"/sar-net-nfs.csv \
		| flatten.py   'call/s'  'retrans/s'  'read/s'  'write/s'  'access/s'  'getatt/s'  > "$destDir"/sar-net-nfs-cleaned.csv

	echo working on sar-network-nfsd.csv
	outlier-remove.py   'scall/s'  'badcall/s'  'packet/s'  'udp/s'  'tcp/s'  'hit/s'  'miss/s'  'sread/s'  'swrite/s'  'saccess/s'  'sgetatt/s' < "$srcDir"/sar-net-nfsd.csv \
		| flatten.py   'scall/s'  'badcall/s'  'packet/s'  'udp/s'  'tcp/s'  'hit/s'  'miss/s'  'sread/s'  'swrite/s'  'saccess/s'  'sgetatt/s' > "$destDir"/sar-net-nfsd-cleaned.csv

	echo working on sar-network-socket.csv
	outlier-remove.py   'totsck'  'tcpsck'  'udpsck'  'rawsck'  'ip-frag'  'tcp-tw' < "$srcDir"/sar-net-sock.csv \
		| flatten.py   'totsck'  'tcpsck'  'udpsck'  'rawsck'  'ip-frag'  'tcp-tw' > "$destDir"/sar-net-sock-cleaned.csv

	echo working on sar-context.csv
	outlier-remove.py   'proc/s'  'cswch/s' < "$srcDir"/sar-context.csv \
		| flatten.py   'proc/s'  'cswch/s' > "$destDir"/sar-context-cleaned.csv

	echo working on sar-cpu.csv
	# extracted with -u ALL, so all CPU on one line
	outlier-remove.py   '%usr'  '%nice'  '%sys'  '%iowait'  '%steal'  '%irq'  '%soft'  '%guest'  '%idle' < "$srcDir"/sar-cpu.csv \
		| flatten.py   '%usr'  '%nice'  '%sys'  '%iowait'  '%steal'  '%irq'  '%soft'  '%guest'  '%idle' > "$destDir"/sar-cpu-cleaned.csv


	echo working on sar-io-default.csv
	outlier-remove.py   'tps'  'rtps'  'wtps'  'bread/s'  'bwrtn/s' < "$srcDir"/sar-io.csv \
		| flatten.py   'tps'  'rtps'  'wtps'  'bread/s'  'bwrtn/s' > "$destDir"/sar-io-cleaned.csv

	echo working on sar-io-tps-combined.csv
	outlier-remove.py   'tps'  'rtps'  'wtps' < "$srcDir"/sar-io.csv \
		| flatten.py   'tps'  'rtps'  'wtps' > "$destDir"/sar-io-cleaned.csv

	echo working on sar-io-blks-per-second-combined.csv
	outlier-remove.py   'bread/s'  'bwrtn/s' < "$srcDir"/sar-io.csv \
		| flatten.py   'bread/s'  'bwrtn/s' > "$destDir"/sar-io-cleaned.csv


	echo working on sar-load-runq-threads.csv
	outlier-remove.py   'runq-sz'  'plist-sz'  'ldavg-1'  'ldavg-5'  'ldavg-15' < "$srcDir"/sar-load.csv \
		| flatten.py   'runq-sz'  'plist-sz'  'ldavg-1'  'ldavg-5'  'ldavg-15' > "$destDir"/sar-load-cleaned.csv

	echo working on sar-load-runq.csv
	outlier-remove.py   'runq-sz'  'ldavg-1'  'ldavg-5'  'ldavg-15' < "$srcDir"/sar-load.csv \
		| flatten.py   'runq-sz'  'ldavg-1'  'ldavg-5'  'ldavg-15' > "$destDir"/sar-load-cleaned.csv

	echo working on sar-memory.csv
	outlier-remove.py   'frmpg/s'   'bufpg/s' < "$srcDir"/sar-mem.csv \
		| flatten.py   'frmpg/s'   'bufpg/s' > "$destDir"/sar-mem-cleaned.csv


	echo working on sar-paging-rate.csv
	outlier-remove.py    'pgpgin/s'   'pgpgout/s' < "$srcDir"/sar-paging.csv \
		| flatten.py    'pgpgin/s'   'pgpgout/s' > "$destDir"/sar-paging-cleaned.csv

	echo working on sar-swap-rate.csv
	outlier-remove.py    'pswpin/s'  'pswpout/s' < "$srcDir"/sar-swap-stats.csv \
		| flatten.py    'pswpin/s'  'pswpout/s' > "$destDir"/sar-swap-stats-cleaned.csv 


	echo working on sar-swap-rate.csv
	outlier-remove.py  'kbswpfree'  'kbswpused' '%swpused' 'kbswpcad' '%swpcad'  < "$srcDir"/sar-swap-utilization.csv \
		| flatten.py  'kbswpfree'  'kbswpused' '%swpused' 'kbswpcad' '%swpcad'  > "$destDir"/sar-swap-utilization-cleaned.csv 

#COMMENT


	echo working on sar-kernel-fs.csv
	outlier-remove.py 'dentunusd'  'file-nr'  'inode-nr'  'pty-nr'   < "$srcDir"/sar-kernel-fs.csv \
		| flatten.py  'dentunusd'  'file-nr'  'inode-nr'  'pty-nr' > "$destDir"/sar-kernel-fs-cleaned.csv



