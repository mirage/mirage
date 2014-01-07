#!/bin/sh

echo This uses the 'fat' command-line tool to build a simple FAT
echo filesystem image.

FAT=$(which fat)
IMG=$(pwd)/fat.img

if [ ! -x "${FAT}" ]; then
  echo I couldn\'t find the 'fat' command-line tool.
  echo Try running 'opam install fat-filesystem'
  exit 1
fi

rm -f ${IMG}
${FAT} create
cd t/
${FAT} add ${IMG} *
echo Created 'fat.img'
