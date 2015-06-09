export EXTRA_REMOTES=https://github.com/mirage/mirage-dev.git

bash -ex .travis-opam.sh

eval `opam config env`
opam install mirage -y
cd lib_test
make MODE=unix MIRAGE=mirage BFLAGS=
make clean
make MODE=xen MIRAGE=mirage BFLAGS=
