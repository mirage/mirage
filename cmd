#!/bin/sh -e
# Script that invokes ocamlbuild commands for various targets

njobs=8

cmd=$1
shift

target=$1

# source the package variables
if [ -e "_vars" ]; then
  . ./_vars
fi

if [ -x "configure.os" ]; then
  . ./configure.os ${target}
fi

OCAMLBUILD=${OCAMLBUILD:-`which ocamlbuild`}
OCAMLFIND=${OCAMLFIND:-`which ocamlfind`}
OCAMLBUILD_FLAGS="-classic-display -j ${njobs}"

# create entries in the _config/ directory
configure() {
  # initialise _config directory
  rm -rf _config && mkdir -p _config
  # _config/inc has -I flags
  ${OCAMLFIND} query -r -i-format ${DEPS} > _config/flags.ocaml
  # _config/archives.* contains dependency archives for linking tests
  ${OCAMLFIND} query -r -a-format -predicates native ${DEPS} > _config/archives.native
  ${OCAMLFIND} query -r -a-format -predicates byte ${DEPS} > _config/archives.byte
  # _config/pp has camlp4 flags for the library and binaries
  ${OCAMLFIND} query -r -predicates syntax,preprocessor -format '-I %d %A' ${DEPS} ${SYNTAX_DEPS} > _config/syntax.deps
  # specially needed for syntax TODO merge with _vars
  ${OCAMLFIND} query -r -predicates byte -format '-I %d %A' str >> _config/syntax.deps
  # _config/syntax has flags to build p4 extensions in syntax/
  ${OCAMLFIND} query -r -predicates syntax,preprocessor -format '-I %d' camlp4.quotations.o camlp4.lib camlp4.extend > _config/syntax.build
  ${OCAMLFIND} query -r -predicates syntax,preprocessor -format '-I %d' camlp4.quotations.r camlp4.lib camlp4.extend ${SYNTAX_DEPS} > _config/syntax.build.r

  echo ${NAME} > _config/name
  echo ${DEPS} > _config/deps
  echo ${SYNTAX} > _config/syntax
  echo ${RUNTIME} > _config/runtime
  echo ${LIB} > _config/lib
  echo ${CFLAGS} > _config/cflags
  echo ${EXTRA} > _config/extra
  # TODO check ocamlopt is installed
  touch _config/flag.opt
  # TODO getopt parsing for this and implement various options
  # touch _config/flag.natdynlink
}

# invoke native code and byte code compiler targets
compile() {
  # build bytecode files and C bindings always
  ${OCAMLBUILD} ${OCAMLBUILD_FLAGS} ${NAME}.all
}

# generate META file and invoke ${OCAMLFIND} installation
install()  {
  sed -e "s/@VERSION@/${VERSION}/g" < META.in > _config/META
  if [ -e META.xenctrl.in ]; then
    sed -e "s/@VERSION@/${VERSION}/g" < META.xenctrl.in > _config/META.xenctrl
  fi
  ${OCAMLFIND} remove ${NAME} || true
  t=`sed -e 's,^,_build/,g' < _build/${NAME}.all`
  if [ ! -z "${DESTDIR}" ]; then
    OCAMLFIND_FLAGS="${OCAMLFIND_FLAGS} -destdir ${DESTDIR}"
  fi
  ${OCAMLFIND} install ${OCAMLFIND_FLAGS} ${NAME} _config/META ${t}
  if [ -e _config/META.xenctrl ]; then
    ${OCAMLFIND} install ${OCAMLFIND_FLAGS} xenctrl _config/META.xenctrl
  fi
}

uninstall() {
  if [ -e META.xenctrl.in ]; then
    ${OCAMLFIND} remove xenctrl
  fi
  if [ -e META.in ]; then
    ${OCAMLFIND} remove mirage
  fi
}

# tests also include the built syntax extensions (if any)
run_tests() {
  for test in ${TESTS}; do
    t="lib_test/$test.byte"
    [ -e _config/flag.opt ] && t="${t} lib_test/$test.native"
    ${OCAMLBUILD} ${OCAMLBUILD_FLAGS} ${t}
  done
}

clean() {
  ${OCAMLBUILD} -clean
  rm -rf _config
}

case "$cmd" in
conf*) configure ;;
compile|build) compile ;;
install) install ;;
uninstall) uninstall ;;
clean) clean ;;
doc) doc ;;
test) run_tests ;;
*) echo unknown command: $cmd; exit 1 ;;
esac
