case "$OCAML_VERSION,$OPAM_VERSION" in
3.12.1,1.1.0) ppa=avsm/ocaml312+opam11 ;;
4.00.1,1.1.0) ppa=avsm/ocaml40+opam11 ;;
4.01.0,1.1.0) ppa=avsm/ocaml41+opam11 ;;
3.12.1,1.2.0) ppa=avsm/ocaml312+opam12 ;;
4.00.1,1.2.0) ppa=avsm/ocaml40+opam12 ;;
4.01.0,1.2.0) ppa=avsm/ocaml41+opam12 ;;
*) echo Unknown $OCAML_VERSION,$OPAM_VERSION; exit 1 ;;
esac

echo "yes" | sudo add-apt-repository ppa:$ppa
sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam libxen-dev
export OPAMYES=1

# when preparing a set of synchronised updates for a Mirage release:
# for regular minor updates:
opam init >/dev/null 2>&1
opam remote add mirage-dev git://github.com/mirage/mirage-dev
opam pin add conduit git://github.com/avsm/ocaml-conduit
opam install cstruct ounit cmdliner ipaddr re lwt io-page xenstore xenstore_transport
eval `opam config env`
opam pin add mirage .
opam pin add mirage-types .
opam install mirage mirage-types

export OPAMVERBOSE=1
# install users of the signatures, to make sure we haven't broken something obvious
opam install mirage-console \
    mirage-clock-unix mirage-clock-xen \
    mirage-block-unix mirage-block-xen \
    fat-filesystem crunch mirage-http \
    mirage-net-xen

make # build ./main.native
cd lib_test
make MODE=unix
make clean
make MODE=xen
