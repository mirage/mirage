#!/bin/sh

TESTPROGRAMS="test-canon testrand testsort tst-calloc tst-environ tst-limits tst-malloc tst-rand48 tst-strtod tst-strtol tst-strtoll tst-system"

for p in $TESTPROGRAMS; do
echo "---";echo testing $p;echo "---"
 ./$p ||  ( echo TESTCASE $p exited non-zero 1>&2 ; sleep 5 )
 done 

echo "12 165 12 10000 10 123 546 752 12 87 98 347 3186 482 92 3941 7563 865 85371 547 28" ./testdiv
