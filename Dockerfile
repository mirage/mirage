FROM ocaml/opam2-staging:4.06
ENV OPAMYES=1

# why this is needed??
RUN opam install opam-depext

# install Mirage base packages
RUN opam depext -i mirage mirage-unix mirage-solo5

RUN sudo sh -c "mkdir -p /src && chown opam /src"
VOLUME /src
WORKDIR /src
