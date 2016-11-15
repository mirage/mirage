eval `opam config env`
rm -rf mirage-skeleton
git clone -b mirage-dev https://github.com/mirage/mirage-skeleton.git
make -C mirage-skeleton
