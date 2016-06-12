bash -ex .travis-opam.sh

eval `opam config env`
opam install mirage -y
git clone -b update-skeleton https://github.com/yomimono/mirage-skeleton.git
cd mirage-skeleton
MODE=unix make
MODE=xen  make
