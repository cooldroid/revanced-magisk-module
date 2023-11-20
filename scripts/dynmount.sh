#!/system/bin/sh
MODDIR="${0%/*}"
PACKAGE_NAME=__PKGNAME

# API_VERSION = 1
STAGE="$1" # prepareEnterMntNs or EnterMntNs
PID="$2" # PID of app process
UID="$3" # UID of app process
PROC="$4" # Process name. Example: com.google.android.gms.unstable
USERID="$5" # USER ID of app
# API_VERSION = 2
# Enable ash standalone
# Enviroment variables: MAGISKTMP, API_VERSION

RUN_SCRIPT(){
    case "$STAGE" in
    "prepareEnterMntNs")
        prepareEnterMntNs
        ;;
    "EnterMntNs")
        EnterMntNs
        ;;
    "OnSetUID")
        OnSetUID
        ;;
    esac
}

prepareEnterMntNs(){
    # script run before enter the mount name space of app process
    if [[ "$PROC" == "$PACKAGE_NAME"* ]]; then
        exit 0
    fi

    # If you want to modify mounts in EnterMntNs, please call exit 0
    exit 1 # close script if we don't need to modify mounts
}

EnterMntNs(){
    # this function will be run when mount namespace of app process is unshared
    base_path="/data/adb/rvhc/${MODDIR##*/}.apk"
    stock_path=$(pm path $PACKAGE_NAME | head -1 | sed 's/^package://g' )
    if [ -z "$stock_path" ]; then exit 0; fi
    chcon u:object_r:apk_data_file:s0 "$base_path"
    mount -o bind "$base_path" "$stock_path"
    # call exit 0 to let script to be run in OnSetUID
    exit 1
}

OnSetUID(){
    # this function will be run when UID is changed from 0 to $UID
    exit 1 # close script
}

RUN_SCRIPT
