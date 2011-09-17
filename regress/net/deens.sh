#!/bin/bash -ex

case $1 in
  prerun ) 
    echo HELLO DEENS EXTERNAL PRERUN
  ;;
  postrun )
    echo HELLO DEENS EXTERNAL POSTRUN
  ;;
  * )
    echo HELLO DEENS EXTERNAL OTHER== $1
  ;;
esac

