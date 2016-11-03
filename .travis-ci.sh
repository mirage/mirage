opam depext -uiy mirage
git clone -b mirage-dev https://github.com/mirage/mirage-skeleton.git
cd mirage-skeleton
eval `opam config env`
find . -name _build | xargs rm -rf
make
