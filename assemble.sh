#!/usr/bin/env bash 
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

set -e
ROOT=`pwd`
BUILDDIR=${ROOT}/_build

function assemble_xen {
  if [ -d ${ROOT}/lib/_build/xen ]; then
    echo Assembling: Xen
    OBJ=${BUILDDIR}/xen
    mkdir -p ${OBJ}/lib ${OBJ}/syntax
    for i in dietlibc/libdiet.a libm/libm.a ocaml/libocaml.a kernel/libxen.a kernel/libxencaml.a kernel/x86_64.o; do
      cp ${ROOT}/lib/_build/xen/os/runtime_xen/$i ${OBJ}/lib/
    done
    cp ${ROOT}/lib/os/runtime_xen/kernel/mirage-x86_64.lds ${OBJ}/lib/
    cp ${ROOT}/lib/_build/xen/std/*.{cmi,cmx,a,o,cmxa} ${OBJ}/lib/
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
  cp ${ROOT}/lib/_build/unix-$1/std/*.{cmi,cmx,cmxa,a,o,cmo} ${OBJ}/lib/
}

function assemble_node {
  mode=$1
  echo Assembling: node
  OBJ=${BUILDDIR}/node
  if [ -d ${ROOT}/lib/_build/node ]; then
    mkdir -p ${OBJ}/lib 
    for i in libos.a dllos.so; do
      cp ${ROOT}/lib/_build/node/os/runtime_node/$i ${OBJ}/lib/
    done
    cp ${ROOT}/lib/_build/node/std/*.{cmi,cmo,cma} ${OBJ}/lib/
    cp ${ROOT}/lib/os/runtime_node/*.js ${OBJ}/lib/
  else
    echo Skipping: Node
  fi
}

function assemble_syntax {
  echo Assembling: camlp4 extensions
  OBJ=${BUILDDIR}/syntax
  mkdir -p ${OBJ}
  cp ${ROOT}/syntax/_build/*.{cma,cmi,cmo,cmxs} ${OBJ}/ || true
}

function assemble_scripts {
  echo Assembling: scripts
  OBJ=${BUILDDIR}/scripts
  mkdir -p ${OBJ}
  cp ${ROOT}/scripts/myocamlbuild.ml ${OBJ}/
}

function assemble_bin {
  echo Assembling: binaries
  OBJ=${BUILDDIR}/bin
  mkdir -p ${OBJ}
  sed -e "s,@MIRAGELIB@,${PREFIX},g" < ${ROOT}/scripts/mir-build > ${OBJ}/mir-build
  cp ${ROOT}/scripts/mir-run ${OBJ}/mir-run
  chmod 755 ${OBJ}/mir-build ${OBJ}/mir-run
  cp ${ROOT}/tools/crunch/_build/crunch.native ${OBJ}/mir-crunch
  cp ${ROOT}/tools/fs/mir-fs-create ${OBJ}/mir-fs-create
  cp ${ROOT}/scripts/mir-fat-create ${OBJ}/mir-fat-create
  cp ${ROOT}/scripts/annot ${OBJ}/annot
}

assemble_syntax
assemble_xen
assemble_unix "direct"
assemble_unix "socket"
assemble_node
assemble_scripts
assemble_bin
