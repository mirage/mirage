#!/bin/bash -e
#
# Assemble a bunch of standard library kernels for the
# various OS configurations:
#
# xen:           direct microkernel
# unix_direct:   UNIX tun/tap with ML net stack
# unix_socket:   UNIX with kernel sockets and no access to lower layers
# node:          node.js backend
#
# These all end up with a set of packed OCaml modules in one directory
# that can be pointed to with -I for compilation against that "kernel".
#
# The myocamlbuild.ml in scripts/ understands the necessary runes to link
# against each of these backends (mainly the library dependencies)

ROOT=`pwd`
BUILDDIR=${ROOT}/_build

function assemble_xen {
  if [ -d ${ROOT}/lib/_build/xen-direct ]; then
    echo Assembling: Xen
    OBJ=${BUILDDIR}/xen-direct
    mkdir -p ${OBJ}/lib ${OBJ}/syntax
    for i in dietlibc/libdiet.a libm/libm.a ocaml/libocaml.a kernel/libxen.a kernel/libxencaml.a kernel/x86_64.o; do
      cp ${ROOT}/lib/_build/xen-direct/os/runtime_xen/$i ${OBJ}/lib/
    done
    cp ${ROOT}/lib/os/runtime_xen/kernel/mirage-x86_64.lds ${OBJ}/lib/
    cp ${ROOT}/lib/_build/xen-direct/std/*.{cmi,cmx,a,o,cmxa} ${OBJ}/lib/
  else
    echo Skipping: Xen
  fi
}

function assemble_unix {
  mode=$1
  echo Assembling: UNIX $1
  OBJ=${BUILDDIR}/unix-$1
  if [ ! -d ${ROOT}/lib/_build/unix-$1 ]; then
    echo Must build unix-$1 first
    exit 1
  fi
  mkdir -p ${OBJ}/lib 
  for i in libunixrun.a main.o; do
    cp ${ROOT}/lib/_build/unix-$1/os/runtime_unix/$i ${OBJ}/lib/
  done
  cp ${ROOT}/lib/_build/unix-$1/std/*.{cmi,cmx,a,o,cmxa} ${OBJ}/lib/
}

function assemble_node {
  if [ -d ${ROOT}/lib/os/_build/node ]; then
    echo Assembling: node
    OBJ=${BUILDDIR}/node-socket
    mkdir -p ${OBJ}/lib ${OBJ}/syntax
    cp ${ROOT}/lib/std/_build/lib/*.{cmi,cma,cmo} ${OBJ}/lib/
    cp ${ROOT}/lib/os/_build/node/oS.{cmi,cma} ${OBJ}/lib/
    for i in runtime.js mirage.js; do
      cp ${ROOT}/lib/os/runtime_node/$i ${OBJ}/lib/
    done
    for i in dllos.so libos.a; do
      cp ${ROOT}/lib/os/_build/runtime_node/$i ${OBJ}/lib/
    done
    cp ${ROOT}/lib/net/socket/_build/node/net.{cmi,cma} ${OBJ}/lib/
    for i in dns http; do
      cp ${ROOT}/lib/$i/_build/node-socket/$i.{cmi,cma} ${OBJ}/lib/;
    done
    cp ${ROOT}/lib/cow/_build/node-socket/lib/cow.{cmi,cma} ${OBJ}/lib/
  else
    echo Skipping: node
  fi
}

function assemble_syntax {
  echo Assembling: camlp4 extensions
  OBJ=${BUILDDIR}/syntax
  mkdir -p ${OBJ}
  cp ${ROOT}/syntax/_build/*.{cma,cmi,cmo} ${OBJ}/
}

function assemble_scripts {
  echo Assembling: scripts
  OBJ=${BUILDDIR}/scripts
  mkdir -p ${OBJ}
  cp ${ROOT}/scripts/myocamlbuild.ml ${OBJ}/
}

assemble_syntax
assemble_xen
assemble_unix "direct"
#assemble_unix "socket"
#assemble_node
assemble_scripts
