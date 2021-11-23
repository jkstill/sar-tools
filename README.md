Another SAR Processor
=======================

asp.sh is a shell script that creates CSV files from sar metrics

asp.pl is a Perl script that creates CSV files from sar metrics

see <a href=https://github.com/jkstill/csv-tools/tree/master/dynachart>dynachart</a> for a script to chart data in Excel with Perl.

<pre>


           /^\/^\
         _|__|  O|
\/     /~     \_/ \
 \____|__________/  \
        \_______      \
                `\     \                 \
                  |     |                  \
                 /      /                    \
                /     /                       \\
              /      /                         \ \
             /     /                            \  \
           /     /             _----_            \   \
          /     /           _-~      ~-_         |   |
         (      (        _-~    _--_    ~-_     _/   |
          \      ~-____-~    _-~    ~-_    ~-_-~    /
            ~-_           _-~          ~-_       _-~
               ~--______-~                ~-___-~


</pre>

## asp.sh

This script was written to process the sar files on a linux or unix system, and output CSV files.

All available files in the source directory will be processed in timestamp order.

If you copy the files from another location, be sure to preserve the timestamps.

Just specify the source and destination directories, and if pretty printing should be used on disk devices.

eg. `./asp.sh -s /var/log/sa -d ./csv -p`

## asp.pl

The `asp.pl` script works similarly to the `asp.sh` script.

The reason for the rewrite is it will be easier to accommodate changes to the sar command options is something other than Bash.

There are still Linux 5 systems out there in production, and the `asp.sh` script no longer works on Linux 5.

I modified `asp.sh` script to use Bash Associtive arrays, as it was much easier to work with than two standard arrays.

Having done so, I then found that the script would not work on Linux 5, as the Bash shell there does not yet have associative arrays.


## Run on the Server

With some options it is important that the sar files be processed on the same server they originated from.'

If for instance, the `--pretty-print` or `--p` option is used, sadf will attempt to match devices to the names used on the system.

The data will be more usable if the devices appear as `/dev/data_disk_01/` than `/dev/vcs2`, or similar.

This only works though if the sar files are processed on the originating server.

## Running the scripts

Both scripts will weed out unsuppoted sar options.

These options are coded in the script. Some Linux versions may not allow some of the options set in the script.

Here is an example from `asp.sh`

```text
# ./asp.sh

Source: /var/log/sa
  Dest: sar-csv

CMD: sadf -d -- -W | head -1 | sed -e 's/;/,/g' > sar-csv/sar-swap-stats.csv
################
CMD: sadf -d -- -n ETCP | head -1 | sed -e 's/;/,/g' > sar-csv/sar-net-etcp.csv
Requested activities not available in file /var/log/sa/sa09

  !!! This Metric Not Supported !!!
  removing  sar-csv/sar-net-etcp.csv  from output
  CMD: sadf -d -- -n ETCP  | head -1 |  sed -e 's/;/,/g'  > sar-csv/sar-net-etcp.csv

################
CMD: sadf -d -- -n SOCK | head -1 | sed -e 's/;/,/g' > sar-csv/sar-net-sock.csv
################
CMD: sadf -d -- -S | head -1 | sed -e 's/;/,/g' > sar-csv/sar-swap-utilization.csv
################
CMD: sadf -d -- -R | head -1 | sed -e 's/;/,/g' > sar-csv/sar-mem.csv
################
CMD: sadf -d -- -n IP | head -1 | sed -e 's/;/,/g' > sar-csv/sar-net-ip.csv
Requested activities not available in file /var/log/sa/sa09

  !!! This Metric Not Supported !!!
  removing  sar-csv/sar-net-ip.csv  from output
  CMD: sadf -d -- -n IP  | head -1 |  sed -e 's/;/,/g'  > sar-csv/sar-net-ip.csv

```


### asp.sh

This script may be run without any options, or just the -p option.

In that case the source directory will be `/var/log/sa`, and the destination directory will be `./sar-csv`.

```text

# ./asp.sh

Processing File: /var/log/sa/sa10
CMD: sadf -d -- -W /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-swap-stats.csv
CMD: sadf -d -- -n SOCK /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-net-sock.csv
CMD: sadf -d -- -S /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-swap-utilization.csv
CMD: sadf -d -- -R /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-mem.csv
CMD: sadf -d -- -n NFSD /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-net-nfsd.csv
CMD: sadf -d -- -n NFS /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-net-nfs.csv
CMD: sadf -d -- -B /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-paging.csv
CMD: sadf -d -- -w /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-context.csv
CMD: sadf -d -- -v /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-kernel-fs.csv
CMD: sadf -d -- -r /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-mem-utilization.csv
CMD: sadf -d -- -q /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-load.csv
CMD: sadf -d -- -n EDEV /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-net-ede.csv
CMD: sadf -d -- -u ALL /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-cpu.csv
CMD: sadf -d -- -b /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-io.csv
CMD: sadf -d -- -n DEV /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-net-dev.csv
CMD: sadf -d -- -d -j ID -p /var/log/sa/sa10 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-disk.csv
Processing File: /var/log/sa/sa11
CMD: sadf -d -- -W /var/log/sa/sa11 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-swap-stats.csv
CMD: sadf -d -- -n SOCK /var/log/sa/sa11 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-net-sock.csv
CMD: sadf -d -- -S /var/log/sa/sa11 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-swap-utilization.csv
CMD: sadf -d -- -R /var/log/sa/sa11 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-mem.csv
CMD: sadf -d -- -n NFSD /var/log/sa/sa11 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-net-nfsd.csv
CMD: sadf -d -- -n NFS /var/log/sa/sa11 | tail -n +2 | sed -e 's/;/,/g' >> sar-csv/sar-net-nfs.csv

...


Processing complete

files located in sar-csv

# ls -l sar-csv/*
-rw-r--r-- 1 root root   236662 Jan  9 15:29 sar-csv/sar-context.csv
-rw-r--r-- 1 root root   394292 Jan  9 15:29 sar-csv/sar-cpu.csv
-rw-r--r-- 1 root root 24984653 Jan  9 15:29 sar-csv/sar-disk.csv
-rw-r--r-- 1 root root   311205 Jan  9 15:29 sar-csv/sar-io.csv
-rw-r--r-- 1 root root   269839 Jan  9 15:29 sar-csv/sar-kernel-fs.csv
-rw-r--r-- 1 root root   267372 Jan  9 15:29 sar-csv/sar-load.csv
-rw-r--r-- 1 root root   247909 Jan  9 15:29 sar-csv/sar-mem.csv
-rw-r--r-- 1 root root   404416 Jan  9 15:29 sar-csv/sar-mem-utilization.csv
-rw-r--r-- 1 root root  1096174 Jan  9 15:29 sar-csv/sar-net-dev.csv
-rw-r--r-- 1 root root  1191420 Jan  9 15:29 sar-csv/sar-net-ede.csv
-rw-r--r-- 1 root root   306808 Jan  9 15:29 sar-csv/sar-net-nfs.csv
-rw-r--r-- 1 root root   416349 Jan  9 15:29 sar-csv/sar-net-nfsd.csv
-rw-r--r-- 1 root root   245476 Jan  9 15:29 sar-csv/sar-net-sock.csv
-rw-r--r-- 1 root root   406471 Jan  9 15:29 sar-csv/sar-paging.csv
-rw-r--r-- 1 root root   219168 Jan  9 15:29 sar-csv/sar-swap-stats.csv
-rw-r--r-- 1 root root   316556 Jan  9 15:29 sar-csv/sar-swap-utilization.csv

```

use the -d and -s options to set the destination and source directories.

## asp.pl

The `asp.pl` script is just a little different in console output, but the same files are created as with `asp.sh`.

```text
# ./asp.pl --source-dir /var/log/sa --dest-dir sar-csv --pretty-print
Dest Dir: sar-csv
CMD is usable: sadf -d -- -d  -j ID -p
CMD is usable: sadf -d -- -n SOCK
CMD is usable: sadf -d -- -n EDEV
CMD is usable: sadf -d -- -S
CMD is usable: sadf -d -- -n DEV
CMD is usable: sadf -d -- -R
CMD is usable: sadf -d -- -w
CMD is usable: sadf -d -- -q
CMD is usable: sadf -d -- -B
CMD is usable: sadf -d -- -n NFSD
CMD is usable: sadf -d -- -v
CMD is usable: sadf -d -- -b
CMD is usable: sadf -d -- -r
CMD is usable: sadf -d -- -u ALL
CMD is usable: sadf -d -- -n NFS
CMD is usable: sadf -d -- -W
working on 'sar -d  -j ID -p   sar-csv/sar-disk.csv'
...............................
working on 'sar -n SOCK sar-csv/sar-net-sock.csv'
...............................

...

working on 'sar -n NFS sar-csv/sar-net-nfs.csv'
...............................
working on 'sar -W sar-csv/sar-swap-stats.csv'
...............................
```


## Auxilary scripts

Following a some useful helper scripts.

If the `-p` option of `asp.sh` is used to match disk devices to logical names, these scripts wlil not be useful.

The `-p` option requires that `asp.sh` be run on the originating server.

### get-sar.sh

Copies sar files from all RAC nodes

### asp-all.sh

Processes the CSV files for all sar files collected.

## sar-map-disks.sh

Creates a sed command file that can be used to replace the devmajor-minor values in the sar output with ASMLib disk names

It is assumed that disks are partitioned.  If not, the script will require some adjustment

## Charting

The charting tools are found at [dynachart](https://github.com/jkstill/csv-tools/tree/master/dynachart)

The use of these tools requires having Perl with the Excel::Writer::XLSX Package installed.

To chart the sar files, just get `sar-chart.sh` and `dynachart.pl`.

```text

# ls -1 
total 108
-rwxr--r-- 1 jkstill dba  8980 Jan  9 15:14 asp.pl
-rwxr--r-- 1 jkstill dba  5235 Jan  7 17:31 asp.sh
-rwxrwxrwx 1 jkstill dba    46 Feb  6  2018 sar-chart.sh
drwxr-xr-x 2 jkstill dba  4096 Jan  8 16:05 sar-csv
-rwxr-xr-x 1 jkstill dba   586 Jan 31  2017 sardisk.sh
drwxrwxr-x 2 jkstill dba  4096 Jan  9 14:53 xlsx

# cd sar-csv

# ../sar-chart.sh  ../xlsx
working on sar-disk-default.xlsx
working on sar-disk-combined.xlsx
working on sar-network-device.xlsx
working on sar-network-error-device.xlsx
working on sar-network-nfs.xlsx
working on sar-network-nfsd.xlsx
working on sar-network-socket.xlsx
working on sar-context.xlsx
working on sar-cpu.xlsx
working on sar-io-default.xlsx
working on sar-io-tps-combined.xlsx
working on sar-io-blks-per-second-combined.xlsx
working on sar-load-runq-threads.xlsx
working on sar-load-runq.xlsx
working on sar-memory.xlsx
working on sar-paging-rate.xlsx
working on sar-swap-rate.xlsx


# ls -l ../xlsx
total 27828
-rwxrwxrwx+ 1 jkstill dba   249103 Jan  9 15:05 sar-context.xlsx
-rwxrwxrwx+ 1 jkstill dba   661059 Jan  9 15:05 sar-cpu.xlsx
-rwxrwxrwx+ 1 jkstill dba 14312309 Jan  9 15:04 sar-disk-combined.xlsx
-rwxrwxrwx+ 1 jkstill dba 14371071 Jan  9 15:04 sar-disk-default.xlsx
-rwxrwxrwx+ 1 jkstill dba   325549 Jan  9 15:05 sar-io-blks-per-second-combined.xlsx
-rwxrwxrwx+ 1 jkstill dba   477240 Jan  9 15:05 sar-io-default.xlsx
-rwxrwxrwx+ 1 jkstill dba   362364 Jan  9 15:05 sar-io-tps-combined.xlsx
-rwxrwxrwx+ 1 jkstill dba   400475 Jan  9 15:05 sar-load-runq-threads.xlsx
-rwxrwxrwx+ 1 jkstill dba   359459 Jan  9 15:05 sar-load-runq.xlsx
-rwxrwxrwx+ 1 jkstill dba   250656 Jan  9 15:05 sar-memory.xlsx
-rwxrwxrwx+ 1 jkstill dba   839133 Jan  9 15:05 sar-network-device.xlsx
-rwxrwxrwx+ 1 jkstill dba   756835 Jan  9 15:05 sar-network-error-device.xlsx
-rwxrwxrwx+ 1 jkstill dba   349468 Jan  9 15:05 sar-network-nfs.xlsx
-rwxrwxrwx+ 1 jkstill dba   624049 Jan  9 15:05 sar-network-nfsd.xlsx
-rwxrwxrwx+ 1 jkstill dba   403746 Jan  9 15:05 sar-network-socket.xlsx
-rwxrwxrwx+ 1 jkstill dba   374887 Jan  9 15:05 sar-paging-rate.xlsx
-rwxrwxrwx+ 1 jkstill dba   194113 Jan  9 15:05 sar-swap-rate.xlsx

```

## More Charting and Data Tools

When faced with large numbers of sar files from multiple servers, it is useful to employ some automation to the data.

For instance, you may have collected sar data from multiple clustered systems.

```text

Directory structure of sar CSV files:

cluster01/
    node01/csv
    node02/csv
    node03/csv
    node04/csv
cluster02/
    node01/csv
    node02/csv
    node03/csv
    node04/csv
...
```

By using some of the tools from the [csv-tools](https://github.com/jkstill/csv-tools) repo, the following can be done:

* create Excel files with charts via `dynachart.pl`
* remove outliers from CSV data
* remove  extreme peaks from CSV data (for better charting of normalized data)
  * create Excel files with charts of the cleansed data
* detect metrics that rise over time

## Cleansing and Charting

The `sar-chart-driver.sh` script calls the following scripts, and runs each on all CSV files in the directory structure

* sar-cleaned.sh
* sar-chart.sh
* sar-chart-cleaned.sh

The result will be three new directories per server:

```text
cluster01/
    node01/csv
    node01/csv-cleaned
    node01/xlsx-cleaned
...
```

## Rising Rate Detector

These scripts are from [csv-tools](https://github.com/jkstill/csv-tools) 

The following files are required from [csv-tools](https://github.com/jkstill/csv-tools)

* csvhdr.sh
* flatten.py
* outlier-remove.py
* rising-rate-detector.py
* rising-rate-detector.sh

The shell script `rising-rate-detector.sh` calls `rising-rate-detector.py` for each of the CSV files.

Any metric that is found to be rising over time will be displayed.

Following is a real example, though the server names have been changed:

```text
$ ./rising-rate-detector.sh | tee rising-rate-detector.log

cluster: rac10
   ============================================
   server: rac10/rac10-p001
cli: rising-rate-detector.py 144 CPU %usr %nice %sys %iowait %steal %irq %soft %guest %idle < rac10/rac10-p001/csv/sar-cpu.csv
%idle is rising
 avgFirstPeriod: 0.026952
avgMiddlePeriod: 0.060606
  avgLastPeriod: 0.060800
     %increased:   126
   ============================================
   server: rac10/rac10-p001
cli: rising-rate-detector.py 144 frmpg/s bufpg/s campg/s < rac10/rac10-p001/csv/sar-mem.csv
frmpg/s is rising
 avgFirstPeriod: 0.004468
avgMiddlePeriod: 0.006022
  avgLastPeriod: 0.012821
     %increased:   187
   ============================================
   server: rac10/rac10-p002
cli: rising-rate-detector.py 144 kbswpfree kbswpused %swpused kbswpcad %swpcad < rac10/rac10-p002/csv/sar-swap-utilization.csv
kbswpused is rising
 avgFirstPeriod: 0.559878
avgMiddlePeriod: 0.893454
  avgLastPeriod: 0.895979
     %increased:    60
%swpused is rising
 avgFirstPeriod: 0.013840
avgMiddlePeriod: 0.166181
  avgLastPeriod: 0.413510
     %increased:  2888
```

The avg values shown do not represent the values from the sar data. Those are just values calculated so periods may be compared.

```




