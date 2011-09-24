#!/bin/sh

case $1 in
prerun)
  echo 12345 > block/bar
  dd if=/dev/zero of=block/bar2 count=1 bs=8199
  echo 12345 >> block/bar2
  ;;
*)
  ;;
esac
