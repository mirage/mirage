opam depext -uiy mirage
git clone -b normalize-ipv4 https://github.com/yomimono/mirage-skeleton.git
cd mirage-skeleton
eval `opam config env`
find . -name _build | xargs rm -rf
make
