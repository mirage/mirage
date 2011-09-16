#!/bin/sh

case $1 in
prerun)
  dd if=/dev/zero of=foo1.img count=1
  dd if=/dev/zero of=foo2.img count=1
  ;;
*)
  ;;
esac
