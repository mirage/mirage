#!/bin/sh
# $Id: camlp4-byte-only.sh 9099 2008-10-23 15:29:11Z ertai $
set -e
cd `dirname $0`/..
. build/targets.sh
set -x
$OCAMLBUILD $@ byte_stdlib_mixed_mode $OCAMLC_BYTE $OCAMLLEX_BYTE $CAMLP4_BYTE
