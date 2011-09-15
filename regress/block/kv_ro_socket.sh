#!/bin/sh

case $1 in
prerun)
  echo 12345 > block/bar
  ;;
*)
  ;;
esac
