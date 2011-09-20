#!/bin/sh -ex

if [ "$1" != "prerun" ]; then exit 0; fi

SIZE=8
OUTPUT=miragefat.img
      
case `uname -s` in
  Darwin )
    hdiutil create -ov -megabytes ${SIZE} -layout NONE -fs MS-DOS -volname MirageFAT -o ${OUTPUT}
    mv ${OUTPUT}.dmg ${OUTPUT}
  ;;

  Linux )
    dd if=/dev/zero of=${OUTPUT} bs=1 seek=128M count=0
    /sbin/mkfs.msdos -n MirageFAT -F 16 -v ${OUTPUT}
    rm -rf tmpmount
    mkdir tmpmount
    sudo mount -o loop ${OUTPUT} tmpmount
    sudo sh -c 'echo 12345 > tmpmount/bar1'
    sudo umount tmpmount
  ;;

  * )
    echo Unknown OS detected
    exit 1
  ;;
esac
