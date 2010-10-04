#!/sbin/sh
PATH=/sbin
if grep -q ' mmcblk0p4$' /proc/partitions ; then
	rm /dev/block/mmcblk0p2
	ln -s /dev/block/mmcblk0p4 /dev/block/mmcblk0p2
	umount /data
fi
rm /etc
mkdir /etc
mount -t rfs /dev/block/stl11 /cache
mount -t vfat /dev/block/mmcblk0p1 /sdcard
if test -e /cache/recovery/command -a \
		"x$(cat /cache/recovery/command)" = "x--update_package=CACHE:update.zip" && \
		cmp /cache/update.zip /sdcard/clockworkmod/recovery-update.zip ; then
	rm /cache/update.zip
	rm /cache/recovery/command
fi
exec /sbin/recovery.bin "${@}"
