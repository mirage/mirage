eval `opam config env`
opam depext -uiy mirage
cd ~
git clone -b releng-3.5.0 https://github.com/hannesm/mirage-skeleton.git
make -C mirage-skeleton && rm -rf mirage-skeleton
