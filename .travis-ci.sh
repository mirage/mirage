eval `opam config env`
opam depext -uiy mirage
cd ~

# pin conduit
CONDUIT=https://github.com/samoht/ocaml-conduit.git#simplify-conduit-mirage
opam pin -n add conduit.2.3.0 $CONDUIT
opam pin -n add conduit-lwt.2.3.0 $CONDUIT
opam pin -n add conduit-mirage.2.3.0 $CONDUIT

# pin cohttp
COHTTP=https://github.com/samoht/ocaml-cohttp.git#conduit-2.3
opam pin -n add cohttp.2.3.0 $COHTTP
opam pin -n add cohttp-lwt.2.3.0 $COHTTP
opam pin -n add cohttp-mirage.2.3.0 $COHTTP

git clone https://github.com/samoht/mirage-skeleton.git#conduit-2.3
make -C mirage-skeleton && rm -rf mirage-skeleton
