#!/bin/sh -ex

if [ "$1" != "prerun" ]; then exit 0; fi

INPUT=rootdir
OUTPUT=miragefat.img

mkdir -p rootdir && echo 12345 > rootdir/bar1

case `uname -s` in
  Darwin )
    # -F 12 = FAT12
    # -f 2880 = standard format, 1.4MB floppy :)
    
    # NB. this creates a boot sector with reserved_sectors=0x08;
    # mirage fat implementation expects 0x00.

    hdiutil create -ov -srcfolder ${INPUT} -fsargs "-F 12 -f 2880" -fs MS-DOS -volname MirageFAT -o ${OUTPUT} -format UDRW -scrub
    mv ${OUTPUT}.dmg ${OUTPUT}
  ;;

  Linux )
    dd if=/dev/zero of=${OUTPUT} bs=1 seek=128M count=0
    /sbin/mkfs.msdos -n MirageFAT -F 16 -v ${OUTPUT}
    rm -rf tmpmount && mkdir tmpmount
    sudo mount -o loop ${OUTPUT} tmpmount
    sudo cp -r ${INPUT} tmpmount
    sudo umount tmpmount
  ;;

  * )
    echo Unknown OS detected
    exit 1
  ;;
esac
