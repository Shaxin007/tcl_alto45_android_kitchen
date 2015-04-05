#!/usr/bin/env bash
SOURCE_ROM=$1
VER=`cat version`
if [ -z $VER ]; then
    VER=1
else
    let "VER++"
fi
if [ ! -d release ]; then
    mkdir release
fi
if [ -d target ]; then
    rm -rf target
fi
echo $VER > version
mkdir target
echo "Extracting source rom..."
mkdir tmp
unzip $SOURCE_ROM -d tmp
BUILD_VER=`grep ro.build.version.incremental tmp/system/build.prop | cut -d \= -f 2`
echo "Cleaning up source rom..."
for f in $(cat clean.txt); do
    if rm -rf tmp/$f; then
        echo "removed tmp/$f"
     else
        echo "Not found tmp/$f"
     fi
done;
cp -r tmp/META-INF target/
cp -r tmp/system target/
cp tmp/file_contexts target/
echo "Applying patch..."
cp -r overlay/* target/
grep ro.build tmp/system/build.prop > target/system/build.prop
cat overlay/system/build.prop >> target/system/build.prop
rm -rf tmp
echo "Complete!"
echo "Packing update.zip"
cd target
zip -r ../release/Alto45_${BUILD_VER}_#${VER}.zip ./*
cd ../
rm -rf target
echo "Complete! Update file: Alto45_${BUILD_VER}_#${VER}.zip"
