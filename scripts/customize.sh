# shellcheck disable=SC2148,SC2086,SC2115
ui_print ""

if [ "$BOOTMODE" != "true" ]; then
    abort "! Recovery install is not supported"
fi

MAGISKTMP="$(magisk --path)" || MAGISKTMP=/sbin

if [ ! -d "$MAGISKTMP/.magisk/modules/magisk_proc_monitor" ]; then
    ui_print "! Please install Magisk Process monitor tool v1.1+"
    ui_print "  https://github.com/HuskyDG/magisk_proc_monitor"
    abort
fi

if [ $ARCH = "arm" ]; then
	#arm
	ARCH_LIB=armeabi-v7a
	alias cmpr='$MODPATH/bin/arm/cmpr'
elif [ $ARCH = "arm64" ]; then
	#arm64
	ARCH_LIB=arm64-v8a
	alias cmpr='$MODPATH/bin/arm64/cmpr'
else
	abort "ERROR: unsupported arch: ${ARCH}"
fi
set_perm_recursive $MODPATH/bin 0 0 0755 0777

BASEPATH=$(pm path __PKGNAME | grep base)
BASEPATH=${BASEPATH#*:}
INS=true
if [ "$BASEPATH" ]; then
	if [ ! -d ${BASEPATH%base.apk}lib ]; then
		ui_print "* Invalid installation found. Uninstalling..."
		pm uninstall -k --user 0 __PKGNAME
	elif cmpr $BASEPATH $MODPATH/__PKGNAME.apk; then
		ui_print "* __PKGNAME is up-to-date"
		INS=false
	fi
fi
if [ $INS = true ]; then
	ui_print "* Updating __PKGNAME (v__PKGVER)"
	set_perm $MODPATH/__PKGNAME.apk 1000 1000 644 u:object_r:apk_data_file:s0
	if ! op=$(pm install --user 0 -i com.android.vending -r -d $MODPATH/__PKGNAME.apk 2>&1); then
		ui_print "ERROR: APK installation failed!"
		abort "$op"
	fi
	BASEPATH=$(pm path __PKGNAME | grep base)
	BASEPATH=${BASEPATH#*:}
	if [ -z "$BASEPATH" ]; then
		abort "ERROR: install __PKGNAME manually and reflash the module"
	fi
fi
BASEPATHLIB=${BASEPATH%base.apk}lib/${ARCH}
if [ -z "$(ls -A1 ${BASEPATHLIB})" ]; then
	ui_print "* Extracting native libs"
	mkdir -p $BASEPATHLIB
	if ! op=$(unzip -j $MODPATH/__PKGNAME.apk lib/${ARCH_LIB}/* -d ${BASEPATHLIB} 2>&1); then
		ui_print "ERROR: extracting native libs failed"
		abort "$op"
	fi
	set_perm_recursive ${BASEPATHLIB} 1000 1000 755 755 u:object_r:apk_data_file:s0
fi
ui_print "* Setting Permissions"
set_perm $MODPATH/revanced.apk 1000 1000 644 u:object_r:apk_data_file:s0

ui_print "* Updating live version"
am force-stop __PKGNAME
cat $MODPATH/dynmount.sh > $MAGISKTMP/.magisk/modules/__MODULE_ID/dynmount.sh
cat $MODPATH/revanced.apk > $MAGISKTMP/.magisk/modules/__MODULE_ID/revanced.apk

ui_print "* Cleanup"
rm -rf $MODPATH/bin $MODPATH/__PKGNAME.apk

ui_print "* Done"
ui_print "  by CoolDroid (github.com/cooldroid)"
ui_print " "
