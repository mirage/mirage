#!/bin/sh

TESTPROGRAMS="memccpy memchr memcmp memcpy memrchr strcasecmp strcmp strlen strncat strncpy strrchr strstr strspn strcspn strpbrk"

for p in $TESTPROGRAMS; do
echo "---";echo testing $p;echo "---"
 ./$p ||  ( echo TESTCASE $p exited non-zero 1>&2 ; sleep 5 )
 done 

