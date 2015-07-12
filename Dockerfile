FROM avsm/docker-opam-build:ubuntu-14.04-ocaml-4.02.1
MAINTAINER Anil Madhavapeddy <anil@recoil.org>

# add entrypoint script
#
USER root
ADD .opam-config-exec /usr/bin/opam-config-exec
RUN chmod 755 /usr/bin/opam-config-exec
USER opam

# setup opam environment
#
ENV OPAMVERBOSE 1
ENV OPAMYES 1
ENV OPAMJOBS 2

RUN opam install mirage

# entry
#
ENTRYPOINT ["/usr/bin/opam-config-exec", "mirage"]
CMD ["bash"]
