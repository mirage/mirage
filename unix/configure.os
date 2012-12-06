#!/bin/sh
# Depending on the architecture, symlink in the correct tap_stubs file.

OS=`uname -s`

CFLAGS=${CFLAGS:--Wall -O3}
case `uname -m` in
armv7l)
  CFLAGS="${CFLAGS} -fPIC"
  ;;
x86_64)
  CFLAGS="${CFLAGS} -fPIC"
  ;;
esac

case "$OS" in
Darwin)
  ln -nsf tap_stubs_macosx.c lib/tap_stubs_os.c
  ;;
Linux)
  ln -nsf tap_stubs_linux.c lib/tap_stubs_os.c
  ;;
*)
  echo Unknown arch $OS
  exit 1
esac
