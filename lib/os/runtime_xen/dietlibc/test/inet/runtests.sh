#!/bin/sh

TESTPROGRAMS="test_ifindex tst-gethnm tst-ntoa"

for p in $TESTPROGRAMS; do
echo "---";echo testing $p;echo "---"
 ./$p ||  ( echo TESTCASE $p exited non-zero 1>&2 ; sleep 5 )
 done 


