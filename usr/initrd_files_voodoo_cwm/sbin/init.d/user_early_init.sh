#!/sbin/sh
# Run user early init programs. These run before /data and /dbdata are mounted,
# and may mount /data and /dbdata. If /data or /dbdata are not mount points
# after early init completes, then they will be mounted using the standard
# devices and filesystems. All operations are logged to /system/user.log.
export PATH=/usr/sbin:/usr/bin:/sbin:/system/xbin:/system/bin
mv /system/user.log /system/user.log.old
exec >>/system/user.log
exec 2>&1
cd /sbin/init.d
echo $(date) SYSTEM EARLY INIT START
for file in E* ; do
    if [ ! -e "$file" ] ; then continue ; fi
    echo "START '$file'"
    /sbin/sh "$file"
    echo "EXIT '$file' ($?)"
done
echo $(date) SYSTEM EARLY INIT DONE
echo $(date) USER EARLY INIT START
if cd /system/etc/init.d >/dev/null 2>&1 ; then
    if [ ! -e "$file" ] ; then continue ; fi
    echo "START '$file'"
    /sbin/sh "$file"
    echo "EXIT '$file' ($?)"
fi
echo $(date) USER EARLY INIT DONE
# Do this here instead of back in init.rc so that it can be conditional on the
# target not already being a mount point.
if ! mountpoint /data ; then
    echo "MOUNT /data"
    if mount -t rfs -o noatime,nosuid,nodev,check=no /dev/block/mmcblk0p2 /data ; then
        echo "SUCCESS"
    else
        echo "FAILURE ($?)"
    fi
fi
if ! mountpoint /dbdata ; then
    echo "MOUNT /dbdata"
    if mount -t rfs -o noatime,nosuid,nodev,check=no /dev/block/stl10 /dbdata ; then
        echo "SUCCESS"
    else
        echo "FAILURE ($?)"
    fi
fi
umount /sdcard
umount /sdext
# Allow init to proceed
read s </sync_fifo
