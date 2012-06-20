#!/bin/sh
# Depending on the architecture, symlink in the correct tap_stubs file.

OS=`uname -s`

CFLAGS=${CFLAGS:--Wall -O3}
case `uname -m` in
x86_64)
  CFLAGS="${CFLAGS} -fPIC"
  ;;
esac

case "$OS" in
Darwin)
  ln -nsf tap_stubs_macosx.c runtime/tap_stubs_os.c
  ;;
Linux)
  ln -nsf tap_stubs_linux.c runtime/tap_stubs_os.c
  ;;
*)
  echo Unknown arch $OS
  exit 1
esac
