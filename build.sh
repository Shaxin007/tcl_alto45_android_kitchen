#!/usr/bin/env bash

if [ -z $1 ]; then
    echo "Usage: ./build.sh path_to_source_rom.zip [product:CM/MIUI] [VERSION:5.4.4 or 11 for cm] [addons:gapps,input-xperia]"
fi

SOURCE=$1
PRODUCT=$2
PRODUCT_NUMBER=$3
ADDONS=$4

MODEL=5042D
BRAND=TCL
DEVICE=Alto45
BOARD=msm8916
LANGUAGE=ru
REGION=RU
INPUT_LOCATE=:ru_RU:en_US
TIMEZONE=Europe/Moscow
USER=$(whoami)
HOST=$(hostname)
PLATFORM=4.4.4
SDK=19
BUILD_NUMBER=`cat .inc`
if [ -z BUILD_NUMBER ]; then
    BUILD_NUMBER=1
else
    let "BUILD_NUMBER++"
fi
echo ${BUILD_NUMBER} > .inc
BUILD_ID=$(git rev-parse HEAD | cut -c1-10)
BUILD_DATE=$(date -R)
BUILD_DATE_SHORT=$(date +%d-%m-%Y)
BUILD_DATE_UTC=$(date +%s)
BUILD_VARIANT="userdebug"
BUILD_VERSION_TAGS="test-keys"
VERSION="${PRODUCT}_${PRODUCT_NUMBER}_${DEVICE}_${BUILD_NUMBER}"
OTA_SERVER="http://alto45-ota.tk"

gen_props() {
    eval "echo \"$(cat $1)\"" >> $2
}

mr_proper() {
    for f in $(cat $1/clean.txt); do
        if rm -rf target/$f; then
            echo "Mr propper said, that target/$f has been sent to /dev/null"
        fi
    done
}

if [ ! -d release ]; then
    mkdir release
fi

if [ -d target ]; then
    rm -rf target
fi

# Extracting source rom
mkdir target
if [ ! -e $SOURCE ]; then
    echo "$SOURCE not found"
    exit 1
fi
mkdir tmp
if [ -d $SOURCE ]; then
    echo "Copying source rom..."
    cp -r $SOURCE/* tmp/
else
    echo "Extracting source rom..."
    unzip $SOURCE -d tmp
fi;

cp -r tmp/META-INF target/
cp -r tmp/system target/
cp tmp/file_contexts target/
rm -rf tmp

# Vendor
echo "Copying vendor files"
cp -r vendor/* target/

# Making build.prop
echo "Making build.prop"
cat /dev/null > target/system/build.prop
gen_props build.prop target/system/build.prop
gen_props vendor/system/build.prop target/system/build.prop

# Product
echo "Call to mr proper..."
mr_proper product/${PRODUCT}

# if contains build.prop
if [ -f product/${PRODUCT}/product.prop ]; then
    gen_props product/${PRODUCT}/product.prop target/system/build.prop
fi

# if contains splash
if [ -f product/${PRODUCT}/splash.img ]; then
    echo "Copying custom splash"
    cp product/${PRODUCT}/splash.img target/splash.img
fi

# if contains boot
if [ -f product/${PRODUCT}/boot.img ]; then
    echo "Copying custom boot"
    cp product/${PRODUCT}/boot.img target/boot.img
fi

# if contains overlay
if [ -d product/${PRODUCT}/overlay ]; then
    echo "Copying overlay"
    cp -r product/${PRODUCT}/overlay/* target/
fi

# Installer
if [ -f product/${PRODUCT}/updater-script ]; then
    echo "Generating updater-script"
    # if updater exist
    if [ -d product/${PRODUCT}/updater ]; then
        cp -r product/${PRODUCT}/updater/* target/META-INF/com/google/android/
    else
        cp -f updater/update-binary target/META-INF/com/google/android/update-binary
    fi
    # generate updater-script
    echo "$(VENDOR_SYMLINKS=$(envsubst < updater/vendor-symlinks) \
        PRODUCT_UPDATER=$(envsubst < product/${PRODUCT}/updater-script) \
        envsubst < updater/updater-script)" > target/META-INF/com/google/android/updater-script
else
    echo "Product updater-script not found!!!"
    exit 1
fi

# Addons
echo "Installing addons..."
for addon in ${ADDONS//,/ }; do
    if [ -d addons/${addon} ]; then
        echo "Call to mr proper..."
        mr_proper addons/${addon}
        echo "Installing $addon..."
        cp -r addons/${addon}/overlay/* target/
    fi
done

# Packing new rom
echo "Packing $VERSION.zip"
cd target
zip -r ../release/$VERSION.zip ./*
cd ../
rm -rf target
md5=($(md5sum release/$VERSION.zip))
# md5 sum for ota
echo $md5 > release/$VERSION.zip.md5sum
# changelist
touch release/$VERSION.txt

echo "Complete! Update file: $VERSION.zip"
