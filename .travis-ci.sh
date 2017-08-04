eval `opam config env`
opam depext -uiy mirage
cd ~
# needed for dns.mirage fix - revert to master from mirage when fixed -yomimono
git clone -b name-changes https://github.com/yomimono/mirage-skeleton.git
make -C mirage-skeleton && rm -rf mirage-skeleton
