#!/bin/sh -ex

if [ "$1" != "prerun" ]; then exit 0; fi

SIZE=8
case `uname -s` in
Darwin)
  hdiutil create -megabytes ${SIZE} -fs MS-DOS -volname MirageFAT -o MirageFAT
  echo How to convert from DMG to raw FAT32 img?
  exit 1
  ;;
Linux)
  dd if=/dev/zero of=miragefat.img bs=1 seek=128M count=0
  /sbin/mkfs.msdos -n MirageFAT -F 16 -v miragefat.img
  rm -rf tmpmount
  mkdir tmpmount
  sudo mount -o loop miragefat.img tmpmount
  sudo sh -c 'echo 12345 > tmpmount/bar1'
  sudo umount tmpmount
  ;;
*)
  echo Unknown OS detected
  exit 1
  ;;
esac
