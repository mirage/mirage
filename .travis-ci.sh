eval `opam config env`
opam depext -uiy mirage
git clone https://github.com/mirage/mirage-skeleton.git
make -C mirage-skeleton && rm -rf mirage-skeleton
