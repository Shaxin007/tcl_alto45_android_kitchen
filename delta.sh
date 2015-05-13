#!/usr/bin/env bash
DEVICE=Alto45

PRODUCT=$1 # PACMAN
VERSION_FROM=$2 # 4.4
VERSION_TO=$3 # 4.4
INREMENTAL_FROM=$4 #200
INREMENTAL_TO=$5 #201
VERSION=incremental-${INREMENTAL_FROM}-${INREMENTAL_TO}

DIR=$(pwd)

FROM=release/${PRODUCT}_${VERSION_FROM}_${DEVICE}_${INREMENTAL_FROM}.zip
TO=release/${PRODUCT}_${VERSION_TO}_${DEVICE}_${INREMENTAL_TO}.zip

mkdir tmp
mkdir tmp/from
mkdir tmp/to
mkdir tmp/delta

echo "Extracting $FROM"
unzip -q $FROM -d tmp/from

echo "Extracting $TO"
unzip -q $TO -d tmp/to

cd $DIR/tmp/to

list=`find . -type f`

echo "Coping diff"
for a in $list; do
   if [ ! -f "$DIR/tmp/from/$a" ]; then
        cp --parents $a $DIR/tmp/delta
      continue
   fi
   diff $a $DIR/tmp/from/$a > /dev/null
   if [[ "$?" == "1" ]]; then
        cp --parents $a $DIR/tmp/delta
   fi
done
# todo удалить файлы, которых нет в новой версии, но присутствуют в старой
echo "Coping done!"

# Installer
cd $DIR
rm -rf tmp/delta/META-INF
cp -r tmp/to/META-INF tmp/delta/
cp tmp/to/boot.img tmp/delta/

if [ -f product/${PRODUCT}/updater-script ]; then
    echo "Generating updater-script"
    # if updater exist
    if [ -d product/${PRODUCT}/updater ]; then
        cp -r product/${PRODUCT}/updater/* tmp/delta/META-INF/com/google/android/
    else
        cp -f updater/update-binary tmp/delta/META-INF/com/google/android/update-binary
    fi
    # generate updater-script
    echo "$(VENDOR_SYMLINKS="" \
        PRODUCT_UPDATER=$(envsubst < product/${PRODUCT}/updater-script) \
        envsubst < updater/updater-script)" > tmp/delta/META-INF/com/google/android/updater-script
else
    echo "Product updater-script not found!!!"
    exit 1
fi

# Packing incremental package
echo "Packing $VERSION.zip"

if [ ! -d delta/$PRODUCT ]; then
    mkdir delta/$PRODUCT
fi

cd $DIR/tmp/delta
zip -q -r $DIR/delta/$PRODUCT/$VERSION.zip ./*
cd $DIR
rm -rf $DIR/tmp

echo "Complete! Delta file: $VERSION.zip"

