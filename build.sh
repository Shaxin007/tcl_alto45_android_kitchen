#!/usr/bin/env bash

if [ -z $1 ]; then
    echo "Usage: ./build.sh path_to_source_rom.zip [product:CM/MIUI] [addons:gapps,input-xperia]"
fi

SOURCE=$1
PRODUCT=$2
ADDONS=$3

VER=`cat version`

if [ -z $VER ]; then
    VER=1
else
    let "VER++"
fi
echo $VER > version

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

# Vendor
echo "Copying vendor files"
cp -r vendor/* target/
# todo нужно определять настройками собирать в system или custpack
rm target/boot_system.img

# Product
echo "Cleaning up..."
for f in $(cat product/${PRODUCT}/clean.txt); do
    if rm -rf target/$f; then
        echo "removed tmp/$f"
     else
        echo "Not found tmp/$f"
     fi
done

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

# Making build.prop
echo "Making build.prop"
cat tmp/system/build.prop >> target/system/build.prop
rm -rf tmp

# Packing new rom
echo "Packing Alto45_${PRODUCT}_#${VER}.zip"
cd target
zip -r ../release/Alto45_${PRODUCT}_#${VER}.zip ./*
cd ../
rm -rf target
echo "Complete! Update file: Alto45_${PRODUCT}_#${VER}.zip"
