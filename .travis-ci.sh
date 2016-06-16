bash -ex .travis-opam.sh

eval `opam config env`
opam install mirage -y
git clone -b sleep-nsec https://github.com/hannesm/mirage-skeleton.git
cd mirage-skeleton
MODE=unix make
MODE=xen  make
