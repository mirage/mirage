#!/bin/sh

case $1 in
prerun)
    rm -rf tmpx
    mkdir -p tmpx
    echo 12345 > tmpx/bar
    dd if=/dev/zero of=block/simplekv.img bs=1024 count=8192
    mir-fs-create tmpx block/simplekv.img
    rm -rf tmpx
    ;;
*)
    ;;
esac
