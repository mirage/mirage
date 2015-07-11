FROM avsm/docker-opam-build:ubuntu-14.04-ocaml-4.02.1
MAINTAINER Anil Madhavapeddy <anil@recoil.org>

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


# setup opam environment
#
ENV OPAMVERBOSE 1
ENV OPAMYES 1
ENV OPAMJOBS 2

# entry
#
ENTRYPOINT ["/usr/bin/opam-config-exec"]
CMD ["bash"]
