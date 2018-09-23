eval `opam config env`
opam depext -uiy mirage
cd ~
git clone -b solo5.0.4.0-renaming https://github.com/mato/mirage-skeleton.git
make -C mirage-skeleton && rm -rf mirage-skeleton
