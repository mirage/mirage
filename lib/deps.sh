#! /usr/bin/env bash -ex

mkdir -p ../pkg && cd ../pkg

LWT=lwt-2.3.1
JS=js_of_ocaml-1.0.3
FINDLIB=findlib-1.2.7

FINDLIB_INSTALLED=$(ocamlfind query -format '%p-%v' findlib || true)
if [ "$FINDLIB_INSTALLED" != "$FINDLIB" ]; then
  if [ "$FINDLIB_INSTALLED" != "" ]; then
    ocamlfind remove findlib || true
  fi
  [ ! -r "$FINDLIB.tar.gz" ] && wget http://download.camlcity.org/download/$FINDLIB.tar.gz
  tar xzvf $FINDLIB.tar.gz && cd $FINDLIB
  ./configure && make all opt install
  
fi

LWT_INSTALLED=$(ocamlfind query -format '%p-%v' lwt || true)
if [ "$LWT_INSTALLED" != "$LWT" ]; then
  if [ "$LWT_INSTALLED" != "" ]; then
    ocamlfind remove lwt || true
  fi
  [ ! -r "$LWT.tar.gz" ] && wget http://ocsigen.org/download/$LWT.tar.gz
  tar xzvf $LWT.tar.gz && cd $LWT
  ocaml setup.ml -configure
  ocaml setup.ml -build
  ocaml setup.ml -install
fi

if [ "$(which js_of_ocaml)" == "" ]; then
  [ ! -r "$JS.tar.gz" ] && wget http://ocsigen.org/download/$JS.tar.gz
  tar xzvf $JS.tar.gz && cd $JS
  make && make install
fi

