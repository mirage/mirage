opam depext -uiy mirage
git clone -b mirage-dev https://github.com/mirage/mirage-skeleton.git
cd mirage-skeleton
eval `opam config env`
MODE=unix make
MODE=xen  make
MODE=ukvm make
MODE=virtio make
