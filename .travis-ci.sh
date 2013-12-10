case "$OCAML_VERSION,$OPAM_VERSION" in
3.12.1,1.1.0) ppa=avsm/ocaml312+opam11 ;;
4.00.1,1.1.0) ppa=avsm/ocaml40+opam11 ;;
4.01.0,1.1.0) ppa=avsm/ocaml41+opam11 ;;
*) echo Unknown $OCAML_VERSION,$OPAM_VERSION; exit 1 ;;
esac

echo "yes" | sudo add-apt-repository ppa:$ppa
sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam
export OPAMYES=1
export OPAMVERBOSE=1

opam init git://github.com/ocaml/opam-repository >/dev/null 2>&1
opam install ocamlfind cstruct ounit mirage-types cmdliner ipaddr re lwt io-page-xen io-page-unix
eval `opam config env`
make
sudo make install
opam install mirage-block-unix

opam install mirage-console-unix mirage-console-xen \
    mirage-clock-unix mirage-clock-xen \
    mirage-block-unix mirage-block-xen \
    fat-filesystem
cd lib_test && make MODE=unix
cd lib_test && make MODE=xen
