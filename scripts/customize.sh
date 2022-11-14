# shellcheck disable=SC2148,SC2086,SC2115
ui_print ""

if [ $ARCH = "arm" ]; then
	alias cmpr='$MODPATH/bin/arm/cmpr'
elif [ $ARCH = "arm64" ]; then
	alias cmpr='$MODPATH/bin/arm64/cmpr'
else
	abort "ERROR: unsupported arch: ${ARCH}"
fi
set_perm_recursive $MODPATH/bin 0 0 0755 0777

basepath() {
	basepath=$(pm path __PKGNAME | grep base)
	echo ${basepath#*:}
}

BASEPATH=$(basepath)
if [ -n "$BASEPATH" ] && cmpr $BASEPATH $MODPATH/__PKGNAME.apk; then
	ui_print "* Installed __PKGNAME and module APKs are identical"
	ui_print "* Skipping stock APK installation"
else
	ui_print "* Updating stock __PKGNAME"
	set_perm $MODPATH/__PKGNAME.apk 1000 1000 644 u:object_r:apk_data_file:s0
	if ! op=$(pm install --user 0 -i com.android.vending -r -d $MODPATH/__PKGNAME.apk 2>&1); then
		ui_print "ERROR: APK installation failed!"
		abort "${op}"
	fi
	BASEPATH=$(basepath)
	if [ -z "$BASEPATH" ]; then
		abort "ERROR: install __PKGNAME manually and reflash the module"
	fi
fi
ui_print "* Setting Permissions"
set_perm $MODPATH/revanced.apk 1000 1000 644 u:object_r:apk_data_file:s0

ui_print "* Extracting youtubervx daemon"
api_level_arch_detect
[ ! -d "$MODPATH/libs/$ABI" ] && abort "! $ABI not supported"
cp -af "$MODPATH/libs/$ABI/youtubervx" "$MODPATH/youtubervx"
rm -rf "$MODPATH/libs"
chcon -R u:object_r:system_file:s0 "$MODPATH/youtubervx"
chmod -R 755 "$MODPATH/youtubervx"
rm -r $MODPATH/bin $MODPATH/__PKGNAME.apk

ui_print "* Optimizing __PKGNAME"
cmd package compile --reset __PKGNAME &

ui_print "* Done"
ui_print "  by j-hc (github.com/j-hc)"
ui_print " "
