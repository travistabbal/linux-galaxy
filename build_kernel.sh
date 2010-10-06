#!/bin/sh
set -e
[ -z "$BUILD_CONFIG" ] && BUILD_CONFIG="./.build_config"
source "$BUILD_CONFIG" 
[ -z "$CROSS_COMPILE" ] && CROSS_COMPILE="${HOME}/x-tools/arm-none-eabi-4.3.4/bin/arm-none-eabi-"
[ -z "$MKZIP" ] && MKZIP='7z -mx9 -mmt=1 a "$OUTFILE" .'
[ -z "$TARGET" ] && TARGET=i897
[ -z "$CLEAN" ] && CLEAN=y
[ -z "$CCACHE" ] && CCACHE="ccache"
[ -z "$DEFCONFIG" ] && DEFCONFIG=y
[ -z "$PRODUCE_TAR" ] && PRODUCE_TAR=y
[ -z "$PRODUCE_ZIP" ] && PRODUCE_ZIP=y
[ -z "$CCACHE_COMPRESS" ] && CCACHE_COMPRESS=1
export CCACHE_DIR
export CCACHE_COMPRESS
if [ "$CLEAN" = "y" ] ; then
	echo "Cleaning source directory."
	make ARCH=arm clean >/dev/null 2>&1
fi
if [ "$DEFCONFIG" = "y" -o ! -f ".config" ] ; then
	echo "Using default configuration for $TARGET"
	make ARCH=arm ${TARGET}_defconfig >/dev/null 2>&1
fi
if [ "$CCACHE" ] && ccache -h &>/dev/null ; then
	echo "Using ccache to speed up compilation."
	CROSS_COMPILE="$CCACHE $CROSS_COMPILE"
fi
case ${TARGET} in
	i897)
		new_TARGET_DEVICE_NAME=SGH-I897
	;;
esac
TARGET_DEVICE_NAME=${TARGET_DEVICE_NAME-${new_TARGET_DEVICE_NAME}}
unset new_TARGET_DEVICE_NAME
do_mount() {
	local p1 p2
	p2=""
	case ${TARGET} in
		i897)
			case $1 in
				/system)
					p1=stl9
				;;
				/dbdata)
					p1=stl10
				;;
				/cache)
					p1=stl11
				;;
				/data)
					p1=mmcblk0p2
					p2=mmcblk0p4
				;;
			esac
		;;
	esac
	if [ -n "$p1" ] ; then
		echo -n "mount(\"rfs\", \"/dev/block/$p1\", \"$1\")"
		if [ -n "$p2" ] ; then
			echo " || mount(\"ext4\", \"/dev/block/$p2\", \"$1\");"
		else
			echo ';'
		fi
	fi
	return 0
}

write_script() {
	test -n "$TARGET_DEVICE_NAME" && \
		echo "assert(getprop(\"ro.product.device\") == \"$TARGET_DEVICE_NAME\" || getprop(\"ro.build.product\") == \"$TARGET_DEVICE_NAME\");"
	declare -f pre_hook >/dev/null 2>&1 && \
		pre_hook
	echo 'ui_print("Unpacking files...");'
	declare -f unpack_hook >/dev/null 2>&1 && \
		unpack_hook
	echo 'package_extract_dir("tmp", "/tmp");'
	declare -f apply_hook >/dev/null 2>&1 && \
		apply_hook
	echo 'ui_print("Flashing kernel...");'
	echo 'write_raw_image("/tmp/zImage", "/dev/block/bml7")'
	declare -f post_hook >/dev/null 2>&1 && \
		post_hook
	return 0
}

prepare_update() {
	rm -fr build/update
	mkdir -p build/update/tmp
	cp -a template/update build
	cp -a arch/arm/boot/zImage build/update/tmp
	write_script >build/update/META-INF/com/google/android/updater-script
	declare -f prepare_hook >/dev/null 2>&1 && \
		prepare_hook
	return 0
}

echo "Cleaning initrd image."
rm usr/initramfs_data.cpio.gz
echo "Beginning compilation, output redirected to build.log."
T1=$(date +%s)
make $MAKEOPTS ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" zImage >build.log 2>&1
T2=$(date +%s)
echo "Compilation took $(($T2 - $T1)) seconds."
VERSION=$(git describe --tags)
if [ "$PRODUCE_TAR" = y ] ; then
	echo "Generating $TARGET-$VERSION.tar for flashing with Odin"
	tar c -C arch/arm/boot zImage >"$TARGET-$VERSION.tar"
fi
if [ "$PRODUCE_ZIP" = y ] ; then
	echo "Generating $TARGET-$VERSION.zip for flashing as update.zip"
	rm -fr "$TARGET-$VERSION.zip"
	prepare_update
	OUTFILE="$PWD/$TARGET-$VERSION.zip"
	cd build/update
	eval "$MKZIP" >/dev/null 2>&1
fi
T3=$(date +%s)
echo "Packaging took $(($T3 - $T2)) seconds."
