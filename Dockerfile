FROM ocaml/opam
RUN sudo apt-get update && sudo apt-get install -y xdot vim && \
  sudo -u opam sh -c "opam depext -u mirage mirage-xen mirage-unix" && \
  sudo -u opam sh -c "opam install -y -j 2 -v mirage mirage-xen mirage-unix" && \
  sudo sh -c "mkdir -p /src && chown opam /src"
VOLUME /src
WORKDIR /src
