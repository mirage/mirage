export FORK_USER=dsheets
export FORK_BRANCH=yorick
export EXTRA_REMOTES=https://github.com/mirage/mirage-dev.git
export PINS="mirage:. mirage-types:. conduit mirage-conduit"

bash -ex .travis-opam.sh

eval `opam config env`
opam install mirage -y
cd lib_test
make MODE=unix MIRAGE=mirage BFLAGS=
make clean
make MODE=xen MIRAGE=mirage BFLAGS=
