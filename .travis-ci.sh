bash -ex .travis-opam.sh

eval `opam config env`
opam install mirage -y
opam source mirage-skeleton
cd mirage-skeleton.dev
MODE=unix make
MODE=xen  make
