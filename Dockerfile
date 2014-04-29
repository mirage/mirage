FROM ubuntu:trusty
MAINTAINER Anil Madhavapeddy <anil@recoil.org>
RUN apt-get -y install sudo pkg-config git build-essential m4 software-properties-common ocaml camlp4-extra ocaml-native-compilers opam
RUN git config --global user.email "docker@example.com"
RUN git config --global user.name "Docker CI"
RUN adduser --disabled-password --gecos "" mirage
RUN passwd -l mirage
ADD .opam-config-exec /usr/bin/opam-config-exec
RUN chmod 755 /usr/bin/opam-config-exec
USER mirage
ENV HOME /home/mirage
ENV OPAMVERBOSE 1
ENV OPAMYES 1
RUN opam init -a
ENTRYPOINT opam-config-exec
