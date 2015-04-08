#!/usr/bin/env bash

if [ -z $1 ]; then
    echo "Usage: ./build.sh path_to_source_rom.zip [product:CM/MIUI] [addons:gapps,input-xperia]"
fi

SOURCE=$1
PRODUCT=$2
ADDONS=$3

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
RELEASE=4.4.4
SDK=19
INCREMENTAL=`cat .inc`
if [ -z INCREMENTAL ]; then
    INCREMENTAL=1
else
    let "INCREMENTAL++"
fi
echo $INCREMENTAL > .inc
BUILD_NUMBER=$(git rev-parse HEAD | cut -c1-10)
BUILD_DATE=$(date -R)
BUILD_DATE_UTC=$(date +%s)
BUILD_ID="${PRODUCT}_${DEVICE}-userdebug $RELEASE $BUILD_NUMBER #$INCREMENTAL test-keys"
VERSION="${PRODUCT}_${DEVICE}_${BUILD_NUMBER}#${INCREMENTAL}"

gen_props() {
local props="
ro.build.id=$BUILD_NUMBER
ro.build.display.id=$BUILD_ID
ro.build.version.incremental=$INCREMENTAL
ro.build.version.sdk=$SDK
ro.build.version.codename=REL
ro.build.version.release=$RELEASE
ro.build.date=$BUILD_DATE
ro.build.date.utc=$BUILD_DATE_UTC
ro.build.type=userdebug
ro.build.user=$USER
ro.build.host=$HOST
ro.build.tags=test-keys
ro.product.brand=$BRAND
ro.product.name=$DEVICE
ro.product.board=$BOARD
ro.product.cpu.abi=armeabi-v7a
ro.product.cpu.abi2=armeabi
ro.product.manufacturer=$BRAND
ro.build.product=$PRODUCT_$MODEL
ro.product.model=$MODEL
ro.product.device=$DEVICE
ro.default.locale.input=$INPUT_LOCATE
ro.product.locale.language=$LANGUAGE
ro.product.locale.region=$REGION
persist.sys.timezone=$TIMEZONE
# Do not try to parse ro.build.description or .fingerprint
ro.build.description=$BUILD_ID
ro.build.fingerprint=$BRAND/$PRODUCT_$DEVICE/$DEVICE:$RELEASE/$BUILD_NUMBER/$INCREMENTAL:userdebug/test-keys
ro.build.characteristics=default
"
echo "$props" > $1
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
# todo нужно определять настройками собирать в system или custpack
rm target/boot_system.img

# Making build.prop
echo "Making build.prop"
gen_props target/system/build.prop
cat vendor/system/build.prop >> target/system/build.prop

# Product
echo "Cleaning up..."
for f in $(cat product/${PRODUCT}/clean.txt); do
    if rm -rf target/$f; then
        echo "removed tmp/$f"
     else
        echo "Not found tmp/$f"
     fi
done

# if contains build.prop
if [ -f product/${PRODUCT}/build.prop ]; then
    cp product/${PRODUCT}/build.prop >> target/system/build.prop
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
if [ -d product/${PRODUCT}/META-INF ]; then
    echo "Copying custom META-INF"
    rm -rf target/META-INF
    cp -r product/${PRODUCT}/META-INF target/
fi

# Addons
echo "Installing addons..."
for addon in ${ADDONS//,/ }; do
    if [ -d addons/${addon} ]; then
        echo "Installing $addon..."
        cp -r addons/${addon}/* target/system/
    fi
done

# Packing new rom
echo "Packing $VERSION.zip"
cd target
zip -r ../release/$VERSION.zip ./*
cd ../
rm -rf target
echo "Complete! Update file: $VERSION.zip"
