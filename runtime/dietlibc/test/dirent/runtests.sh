#!/bin/sh

TESTPROGRAMS="opendir-tst1 tst-seekdir"

for p in $TESTPROGRAMS; do
echo "---";echo testing $p;echo "---"
 ./$p ||  ( echo TESTCASE $p exited non-zero 1>&2 ; sleep 5 )
done 

