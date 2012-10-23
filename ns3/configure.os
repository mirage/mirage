#!/bin/sh
# Depending on the architecture, symlink in the correct tap_stubs file.

OS=`uname -s`

CFLAGS=${CFLAGS:--Wall -O3 -I/usr/local/include/ns3-dev/}
case `uname -m` in
x86_64)
  CFLAGS="${CFLAGS} -fPIC"
  ;;
esac

case "$OS" in
Darwin)
  ;;
Linux)
  ;;
*)
  echo Unknown arch $OS
  exit 1
esac
