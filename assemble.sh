#!/bin/bash -e
#
# Assemble a bunch of standard library kernels for the
# various OS configurations:
#
# xen:           direct microkernel
# unix_direct:   UNIX tun/tap with ML net stack
# unix_socket:   UNIX with kernel sockets and no access to lower layers
#
# These all end up with a set of packed OCaml modules in one directory
# that can be pointed to with -I for compilation against that "kernel".
#
# The myocamlbuild.ml in scripts/ understands the necessary runes to link
# against each of these backends (mainly the library dependencies)

ROOT=`pwd`
BUILDDIR=${ROOT}/_build

function assemble_xen {
  if [ -d ${ROOT}/lib/os/_build/xen ]; then
    echo Assembling: Xen
    OBJ=${BUILDDIR}/xen-direct
    mkdir -p ${OBJ}/lib ${OBJ}/syntax
    cp ${ROOT}/lib/std/_build/lib/*.{cmi,cmxa,a} ${OBJ}/lib/
    cp ${ROOT}/lib/os/_build/xen/oS.{cmi,cmxa,a} ${OBJ}/lib/
    for i in dietlibc/libdiet.a libm/libm.a ocaml/libocaml.a kernel/libxen.a kernel/libxencaml.a kernel/x86_64.o; do
      cp ${ROOT}/lib/os/_build/runtime_xen/$i ${OBJ}/lib/
    done
    cp ${ROOT}/lib/os/runtime_xen/kernel/mirage-x86_64.lds ${OBJ}/lib/
    cp ${ROOT}/lib/net/direct/_build/xen/net.{cmi,cmxa,a} ${OBJ}/lib/
    cp ${ROOT}/lib/block/direct/_build/xen/block.{cmi,cmxa,a} ${OBJ}/lib/
    for i in dns http; do 
      cp ${ROOT}/lib/$i/_build/xen-direct/$i.{cmi,cmxa,a} ${OBJ}/lib/;
    done
    cp ${ROOT}/lib/cow/_build/xen-direct/lib/cow.{cmi,cmxa,a} ${OBJ}/lib/
  else
    echo Skipping: Xen
  fi
}

function assemble_unix_direct {
  echo Assembling: UNIX_direct
  OBJ=${BUILDDIR}/unix-direct
  mkdir -p ${OBJ}/lib ${OBJ}/syntax
  cp ${ROOT}/lib/std/_build/lib/*.{cmi,cmxa,a} ${OBJ}/lib/
  cp ${ROOT}/lib/os/_build/unix/oS.{cmi,cmxa,a} ${OBJ}/lib/
  for i in libunixrun.a main.o; do
    cp ${ROOT}/lib/os/_build/runtime_unix/$i ${OBJ}/lib/
  done
  cp ${ROOT}/lib/net/direct/_build/unix/net.{cmi,cmxa,a} ${OBJ}/lib/
  for i in dns http; do 
    cp ${ROOT}/lib/$i/_build/unix-direct/$i.{cmi,cmxa,a} ${OBJ}/lib/;
  done
  cp ${ROOT}/lib/cow/_build/unix-direct/lib/cow.{cmi,cmxa,a} ${OBJ}/lib/
}

function assemble_unix_socket {
  echo Assembling: UNIX_socket
  OBJ=${BUILDDIR}/unix-socket
  mkdir -p ${OBJ}/lib ${OBJ}/syntax
  cp ${ROOT}/lib/std/_build/lib/*.{cmi,cmxa,a} ${OBJ}/lib/
  cp ${ROOT}/lib/os/_build/unix/oS.{cmi,cmxa,a} ${OBJ}/lib/
  for i in libunixrun.a main.o; do
    cp ${ROOT}/lib/os/_build/runtime_unix/$i ${OBJ}/lib/
  done
  cp ${ROOT}/lib/net/socket/_build/unix/net.{cmi,cmxa,a} ${OBJ}/lib/
  for i in dns http; do 
    cp ${ROOT}/lib/$i/_build/unix-socket/$i.{cmi,cmxa,a} ${OBJ}/lib/;
  done
  cp ${ROOT}/lib/cow/_build/unix-socket/lib/cow.{cmi,cmxa,a} ${OBJ}/lib/
}

function assemble_syntax {
  echo Assembling: camlp4 extensions
  OBJ=${BUILDDIR}/syntax
  mkdir -p ${OBJ}
  cp ${ROOT}/lib/std/_build/syntax/pa_*.cma ${OBJ}/
  cp ${ROOT}/lib/dyntype/_build/syntax/*.{cmi,cmo} ${OBJ}/
  cp ${ROOT}/lib/cow/_build/unix-direct/syntax/pa_cow.cmo ${OBJ}/
}

function assemble_scripts {
  echo Assembling: scripts
  OBJ=${BUILDDIR}/scripts
  mkdir -p ${OBJ}
  cp ${ROOT}/scripts/myocamlbuild.ml ${OBJ}/
}

assemble_syntax
assemble_xen
assemble_unix_direct
assemble_unix_socket
assemble_scripts
