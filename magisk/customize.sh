#!/system/bin/sh

## This script is part of the Universal SafetyNet Fix module project.
## kdrag0n @ xda-developers

# Preset device sensitive [secure] properties to the safe value.


# __ Define variables. __

### Magisk variables
## API (value): the API [SDK] level.
## TMPDIR (path): a place where you can temporarily store files.
## MAGISK_VER_CODE (value): running magisk daemon version code.
## MODPATH (path): the path where your module files should be installed.

# Get Android release version.
## Force SDK32 to show as 12L instead of 12
if [ "$API" -eq 32 ]; then
    aOS=12L
else
    aOS=$(getprop ro.build.version.release)
fi

# __ Define functions. __

add_prop() {
    if [ "$(getprop $1)" ]; then
        echo $1"="$2 >>$MODPATH/system.prop
    fi
}

adjust_prop() {
    if [ "$(getprop $1)" ]; then
        if [ "$(getprop $1)" = "$2" ]; then
            echo $1"="$3 >>$MODPATH/system.prop
        fi
    fi
}

check_deny_list() {
    if [ "$(magisk --sqlite "SELECT value FROM settings WHERE key = 'denylist'" | cut -d '=' -f2)" -eq 1 ]; then
        DENYLIST=enforced
    else
        DENYLIST=
    fi
}

check_zygisk() {
    if [ "$(magisk --sqlite "SELECT value FROM settings WHERE key = 'zygisk'" | cut -d '=' -f2)" -eq 1 ]; then
        ZYGISK=enabled
    else
        ZYGISK=
    fi
}

set_default_list() {
    magisk --denylist add com.google.android.gms com.google.android.gms.unstable
    if [ "$(magisk --path)" != "/sbin" ]; then
        magisk --denylist add com.google.android.gms com.google.android.gms
    fi
}


# __ Here we go. __

if [ "$API" -lt 26 ]; then
    ui_print ""
    ui_print "Android $aOS"
    ui_print " Sensitive [secure] properties will be set to the safe value."
    ui_print " - Forced basic attestation is disabled."
    ui_print ""
    rm "$MODPATH/post-fs-data.sh"
    rm -fr "$MODPATH/zygisk"
else
    ui_print ""
    ui_print "Android $aOS"
    ui_print " Sensitive [secure] properties will be set to the safe value."
    ui_print " - Forced basic attestation is enabled."
    ui_print ""
fi

# __ Add sensitive [secure] properties as needed. __

# Create a new 'system.prop' file.
echo "# Device sensitive properties" >$MODPATH/system.prop
echo "" >>$MODPATH/system.prop

ui_print ""
ui_print " Generating a list of 'sensitive [secure]' device properties."
ui_print ""

# Check and include device sensitive [secure] properties.
add_prop ro.adb.secure 1
add_prop ro.boot.selinux enforcing
add_prop ro.boot.warranty_bit 0
add_prop ro.build.tags release-keys
add_prop ro.build.type user
add_prop ro.debuggable 0
add_prop ro.is_ever_orange 0
add_prop ro.odm.build.tags release-keys
add_prop ro.odm.build.type user
add_prop ro.product.build.tags release-keys
add_prop ro.product.build.type user
add_prop ro.system.build.tags release-keys
add_prop ro.system.build.type user
add_prop ro.vendor.boot.warranty_bit 0
add_prop ro.vendor.build.tags release-keys
add_prop ro.vendor.build.type user
add_prop ro.vendor.warranty_bit 0
add_prop ro.warranty_bit 0

# __ Add GMS to Magisk's Denylist if needed. __

# Add SafetyNet by default on Android 7.x and below. __
if [ "$API" -lt 26 ] && [ "$MAGISK_VER_CODE" -ge 24000 ]; then
    ui_print ""
    ui_print " Adding required Google Play services to Magisk's Denylist."
    ui_print ""
    set_default_list
fi

# __ Check Magisk settings. __

# Android 8 and newer.
if [ "$API" -ge 26 ] && [ "$MAGISK_VER_CODE" -ge 24000 ]; then
    check_zygisk
    if [ -z "$ZYGISK" ]; then
        ui_print ""
        ui_print " Zygisk is not enabled."
        ui_print ""
        ui_print " Zygisk is required to force basic attestation."
        ui_print " - Make sure to enable Zygisk in Magisk."
        ui_print ""
    fi
fi

# Android 7.x and older.
if [ "$API" -lt 26 ] && [ "$MAGISK_VER_CODE" -ge 24000 ]; then
    check_zygisk
    if [ -z "$ZYGISK" ]; then
        ui_print ""
        ui_print " Zygisk is not enabled."
        ui_print ""
        ui_print " Zygisk is required to enforce the DenyList."
        ui_print " - Make sure to enable Zygisk in Magisk."
        ui_print " - Make sure to enforce the DenyList in Magisk."
        ui_print ""
        ui_print " Ignore this message if you are not utilizing Zygisk."
        ui_print ""
    fi

    if [ -n "$ZYGISK" ]; then
        check_deny_list
        if [ -z "$DENYLIST" ]; then
            ui_print ""
            ui_print " Magisk Denylist is not enforced."
            ui_print ""
            ui_print " Make sure to enforce DenyList in Magisk."
            ui_print ""
            ui_print " Ignore this message if you are not using the denylist."
            ui_print ""
        fi
    fi
fi

# __ Finish and Cleanup. __

# Correct permissions of the script file(s).
for i in "$MODPATH"/*.sh; do
    chmod 0755 $i
done
