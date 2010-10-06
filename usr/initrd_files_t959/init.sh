#!/bin/sh

set -x
PATH=/bin:/sbin:/usr/bin/:/usr/sbin

# proc and sys are  used
mount -t proc proc /proc
mount -t sysfs sys /sys


# create used devices nodes
mkdir /dev/block
mkdir /dev/snd

# standard
mknod /dev/null c 1 3
mknod /dev/zero c 1 5

# internal & external SD
mknod /dev/block/mmcblk0 b 179 0
mknod /dev/block/mmcblk0p1 b 179 1
mknod /dev/block/mmcblk0p2 b 179 2
mknod /dev/block/mmcblk0p3 b 179 3
mknod /dev/block/mmcblk0p4 b 179 4
mknod /dev/block/mmcblk1 b 179 8
mknod /dev/block/mmcblk1p1 b 179 9
mknod /dev/block/mmcblk1p2 b 179 10
mknod /dev/block/stl1 b 138 1
mknod /dev/block/stl2 b 138 2
mknod /dev/block/stl3 b 138 3
mknod /dev/block/stl4 b 138 4
mknod /dev/block/stl5 b 138 5
mknod /dev/block/stl6 b 138 6
mknod /dev/block/stl7 b 138 7
mknod /dev/block/stl8 b 138 8
mknod /dev/block/stl9 b 138 9
mknod /dev/block/stl10 b 138 10
mknod /dev/block/stl11 b 138 11
mknod /dev/block/stl12 b 138 12

# soundcard
mknod /dev/snd/controlC0 c 116 0
mknod /dev/snd/controlC1 c 116 32
mknod /dev/snd/pcmC0D0c c 116 24
mknod /dev/snd/pcmC0D0p c 116 16
mknod /dev/snd/pcmC1D0c c 116 56
mknod /dev/snd/pcmC1D0p c 116 48
mknod /dev/snd/timer c 116 33


# insmod required modules
insmod /lib/modules/fsr.ko
insmod /lib/modules/fsr_stl.ko
insmod /lib/modules/rfs_glue.ko
insmod /lib/modules/rfs_fat.ko
insmod /lib/modules/j4fs.ko
insmod /lib/modules/dpram.ko


# Run user pre-init scripts. These run BEFORE init.rc is processed and so can modify the ramdisk before boot. 
# /system is mounted here, so that it can find your scripts, then dismounted so init.rc can handle it later. 

export PATH=/sbin:/bin

mount -t rfs /dev/block/stl9 /system

echo $(date) USER PRE INIT START
if cd /system/etc/init.d >/dev/null 2>&1 ; then
    for file in P* ; do
        if ! ls "$file" >/dev/null 2>&1 ; then continue ; fi
        echo "START '$file'"
        /system/bin/sh "$file"
        echo "EXIT '$file' ($?)"
    done
fi

echo $(date) USER INIT DONE

cd /
umount /system


# Start Android init
exec /sbin/init


