#!/bin/sh

if [ "$1" != "prerun" ]; then exit 0; fi

SIZE=8
case `uname -s` in
Darwin)
  hdiutil create -megabytes ${SIZE} -fs MS-DOS -volname MirageFAT -o MirageFAT
  echo How to convert from DMG to raw FAT32 img?
  exit 1
  ;;
Linux)
  echo Linux not supported yet
  ;;
*)
  echo Unknown OS detected
  exit 1
  ;;
esac
