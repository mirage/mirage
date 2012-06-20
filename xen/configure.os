#!/bin/sh -x

case "$1" in
xen)
  CC=${CC:-cc}
  PWD=`pwd`
  GCC_INCLUDE=`env LANG=C ${CC} -print-search-dirs | sed -n -e 's/install: \(.*\)/\1/p'`
  CFLAGS="-U __linux__ -U __FreeBSD__ -U __sun__ -D__MiniOS__ -D__MiniOS__ -D__x86_64__ \
    -D__XEN_INTERFACE_VERSION__=0x00030205 -D__INSIDE_MINIOS__ -nostdinc -std=gnu99 \
    -fno-stack-protector -m64 -mno-red-zone -fno-reorder-blocks -fstrict-aliasing \
    -momit-leaf-frame-pointer -mfancy-math-387 -I${GCC_INCLUDE}/include \
    -isystem ${PWD}/runtime/include/ -isystem ${PWD}/runtime/include/mini-os \
    -isystem ${PWD}/runtime/include/mini-os/x86 -DCAML_NAME_SPACE -DTARGET_amd64 
    -DSYS_xen -I${PWD}/runtime/ocaml -I${PWD}/runtime/libm \
    -Wextra -Wchar-subscripts -Wmissing-prototypes -Wmissing-declarations -Wno-switch \
    -Wno-unused -Wredundant-decls -D__dietlibc__ -I${PWD}/runtime/dietlibc \
    -DNATIVE_CODE"
  ;;
*)
  CC="${CC:-cc}"
  CFLAGS="-Wall -O3"
  ;;
esac
