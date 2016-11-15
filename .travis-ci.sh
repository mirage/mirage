eval `opam config env`
git clone -b mirage-dev https://github.com/mirage/mirage-skeleton.git
make -C mirage-skeleton && rm -rf mirage-skeleton
