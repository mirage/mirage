eval `opam config env`
opam depext -uiy mirage
cd ~
# revert to `git clone -b master https://github.com/mirage/mirage-skeleton.git`
# once mirage-skeleton#257 or equivalent is merged
git clone -b muen-ready https://github.com/yomimono/mirage-skeleton.git
make -C mirage-skeleton && rm -rf mirage-skeleton
