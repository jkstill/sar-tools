To Do List
==========

## Drive Mapping

This is only relevant for Oracle Grid Infrastructure, but is included here as it is sometimes desirable to map the Oracle ASM drives back to the physsical drives.

Doing so allows getting some metrics that are not available in ASM data, such as disk queuing

There are three methods that may be used to configure drives for ASM

The method used to map ASM disks back to physical disks is different for each

* udev
** WIP
* Oracle ASMLib
** /etc/init.d/oracleasm listdisks -d
* Oracle Filter Driver - AFD (ASM Filter Driver)
** asmcmd afd_lsdsk 


This is a work in progress


## References

[How to map an ASMLIB disk to a device name](http://asmsupportguy.blogspot.com/2010/05/how-to-map-asmlib-disk-to-device-name.html)
[kfed - ASM metadata editor ](http://asmsupportguy.blogspot.com/2010/04/kfed-asm-metadata-editor.html)
[ASM disk header ](http://asmsupportguy.blogspot.com/2011/08/asm-disk-header.html)

