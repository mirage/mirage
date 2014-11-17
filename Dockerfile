
FROM ubuntu:trusty
MAINTAINER Anil Madhavapeddy <anil@recoil.org>

# build and source-control tools
#
RUN apt-get update && \
    apt-get -y install \
        pkg-config git build-essential m4 software-properties-common libssl-dev

# opam 1.2 and ocaml 4.01
#
RUN add-apt-repository ppa:avsm/ocaml41+opam12 && \
    apt-get update && \
    apt-get -y install \
        ocaml camlp4-extra ocaml-native-compilers opam


# add entrypoint script
#
ADD .opam-config-exec /usr/bin/opam-config-exec
RUN chmod 755 /usr/bin/opam-config-exec


# add mirage user
#
RUN adduser --gecos "" mirage && \
    passwd -l mirage

USER mirage
ENV HOME /home/mirage
WORKDIR /home/mirage


# git config
#
RUN git config --global user.email "mirage@example.com" && \
    git config --global user.name "Mirage"


# setup opam with mirage-dev remote
#
ENV OPAMVERBOSE 1
ENV OPAMYES 1

RUN opam init -a
RUN opam remote add mirage-dev git://github.com/mirage/mirage-dev


# entry
#
ENTRYPOINT ["/usr/bin/opam-config-exec"]
CMD ["bash"]

