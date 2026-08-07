
Build sadf on Linux 7.  The sadf binary is used to create comma delimited files from the sar binary output.

The sadf built on Linux 7 will work on Linux 8. On Linux 9 and later the standard sadf binary is used.

The method for getting the names of devices changed in sysstat 12.4.0 which was released 2020-07-31.

Prior the that device names were found via `sysstat.ioconf` which could be extremely slow.

So, it was advised to use the `asp.sh` script without the `-p` pretty print option.

After that the lookup is done via `/sys/dev/block/<major>:<minor>`, which just requires a `readlink()` call to get the device name.

The version used here is the latest version of the 12.4.x series, which is 12.4.5.

This is the lowest bar that may work on Linux 8 and maybe even Linux 7.

sha1sum: 69f62e3e98361027e9af0233e84e589731471726

url: https://sysstat.github.io/sysstat-packages/sysstat-12.4.5.tar.xz

## Build sysstat

On a linux 7 system, build sysstat 12.4.5 with the following commands:

```text
./configure --prefix=./
make
```

Then copy the `sadf` binary as `sadf-12.4.5` to this repo.

When running asp.sh on Linux 7 or 8, this binary will be required.

