#!/bin/sh

case $1 in
prerun)
    rm -rf tmpx
    mkdir -p tmpx
    echo 12345 > tmpx/bar
    dd if=/dev/zero of=tmpx/bar2 count=1 bs=4098
    echo 12345 >> tmpx/bar2
    dd if=/dev/zero of=block/simplekv.img bs=512 count=8192
    mir-fs-create tmpx block/simplekv.img
    rm -rf tmpx
    ;;
*)
    ;;
esac
