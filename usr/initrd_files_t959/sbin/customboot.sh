#!/system/bin/sh

if [ -f "/data/local/bootanimation.zip" -o -f "/system/media/bootanimation.zip" ]; then
  setprop rw.kernel.android.customboot 1
else
	setprop rw.kernel.android.stockboot 1
fi

