FROM ocaml/opam2-staging:4.06
ENV OPAMYES=1

# why this is needed??
RUN opam install opam-depext
RUN opam pin -n https://github.com/pqwy/mirage-os-shim.git#pull/4/head

# install Mirage + a few packages
RUN opam depext -i \
    cohttp-mirage \
    crunch \
    mirage \
    mirage-block \
    mirage-block-lwt \
    mirage-block-solo5 \
    mirage-block-unix \
    mirage-bootvar-solo5 \
    mirage-channel \
    mirage-channel-lwt \
    mirage-conduit \
    mirage-clock \
    mirage-clock-freestanding \
    mirage-clock-lwt \
    mirage-clock-unix \
    mirage-console \
    mirage-console-lwt \
    mirage-console-solo5 \
    mirage-console-unix \
    mirage-device \
    mirage-dns \
    mirage-flow \
    mirage-flow-lwt \
    mirage-fs \
    mirage-fs-lwt \
    mirage-kv \
    mirage-kv-lwt \
    mirage-logs \
    mirage-net \
    mirage-net-lwt \
    mirage-net-solo5 \
    mirage-net-unix \
    mirage-profile \
    mirage-protocols \
    mirage-protocols-lwt \
    mirage-random \
    mirage-solo5 \
    mirage-stack \
    mirage-stack-lwt \
    mirage-time \
    mirage-time-lwt \
    mirage-types \
    mirage-types-lwt \
    mirage-unix \
    randomconv \
    tcpip \
    tls \
    tuntap

RUN sudo sh -c "mkdir -p /src && chown opam /src" \
VOLUME /src
WORKDIR /src
