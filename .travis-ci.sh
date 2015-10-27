export EXTRA_REMOTES=https://github.com/mirage/mirage-dev.git

bash -ex .travis-opam.sh

eval `opam config env`
opam install mirage -y
opam source mirage-skeleton
cd mirage-skeleton.dev
MODE=unix make
MODE=xen  make
