eval `opam config env`
opam depext -uiy mirage
cd ~
git clone -b mirage-dev-dune https://github.com/samoht/mirage-skeleton.git
make -C mirage-skeleton && rm -rf mirage-skeleton
