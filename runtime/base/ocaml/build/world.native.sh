#!/bin/sh
# $Id: world.native.sh,v 1.3 2007/10/08 14:19:34 doligez Exp $
set -e
cd `dirname $0`/..
. build/targets.sh
set -x
$OCAMLBUILD $@ \
  $STDLIB_NATIVE $OCAMLC_NATIVE $OCAMLOPT_NATIVE \
  $OCAMLLEX_NATIVE $TOOLS_NATIVE $OTHERLIBS_NATIVE \
  $OCAMLBUILD_NATIVE $OCAMLDOC_NATIVE $CAMLP4_NATIVE
