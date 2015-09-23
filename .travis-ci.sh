bash -ex .travis-opam.sh

eval `opam config env`

opam install mirage --yes
opam source mirage-skeleton
cd mirage-skeleton.dev
MODE=unix make && make clean
MODE=xen  make && make clean
