#!/bin/sh

TESTPROGRAMS="tstdiomisc tst-fdopen tst-fileno tst-fphex tst-fseek tst-printf tst-sprintf tst-sscanf tst-tmpnam tst-unbputc tst-ungetc"

for f in "tstgetln tst-ferror tstscanf";do
echo "
25 54.32E-1 thompson
56789 0123 56a72
2 quarts of oil
-12.8degrees Celsius
lots of luck
10.0LBS      of       fertilizer
100ergs of energy" | ./$f ||  ( echo TESTCASE $f exited non-zero 1>&2 ; sleep 5 )
done

for p in $TESTPROGRAMS; do
echo "---";echo testing $p;echo "---"
 ./$p ||  ( echo TESTCASE $p exited non-zero 1>&2 ; sleep 5 )
done 

