#!/bin/sh
# Sync test crunch fs
# Has to be run by hand for the moment as I do not know how to
# dynamically register an ocamlbuild build output

mkdir -p tmp
cd tmp
echo 12345 > bar
# bigger file
dd if=/dev/zero of=bar2 count=512 bs=1024
echo 12345 >> bar2
mir-crunch -name foo . > ../crunch_kv_ro.ml
rm -rf tmp
