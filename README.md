## MirageOS

MirageOS is a library operating system that constructs unikernels for secure,
high-performance network applications across a variety of cloud computing and
mobile platforms. Code can be developed on a traditional OS such as Linux or
MacOS X, and then compiled into a fully-standalone, specialised unikernel that
runs under the Xen or KVM hypervisors as well as lightweight hypervisors like
BSD's bhyve.  Xen and KVM power many public clouds;
MirageOS unikernels are currently running on Amazon's Elastic Compute Cloud
and Google Compute Engine, and maybe others!

The most up-to-date documentation can be found at the
[homepage](https://mirage.io). The site is self-hosted, and is itself a useful
[example](https://github.com/mirage/mirage-www). Simpler
[skeleton applications](https://github.com/mirage/mirage-skeleton) are also
available online.

[![Build Status](https://travis-ci.org/mirage/mirage.svg)](https://travis-ci.org/mirage/mirage)
[![docs](https://img.shields.io/badge/doc-online-blue.svg)](https://mirage.github.io/mirage/)

### This repository

This repository includes:

* a command-line tool to create and deploy applications with MirageOS; and
* in `types/`, a library of type signatures that compliant applications use.

There are several diverse backends in MirageOS that require rather specialised
build steps (from Xen to KVM unikernels), and this complexity is wrapped
up in the tool.

To work with `mirage`, you'll need to either install prerequisites
locally or use the Docker image.

**Local install**

You will need the following:

* a working [OCaml](https://ocaml.org) compiler (4.03.0 or higher).
* the [OPAM](https://opam.ocaml.org) source package manager (1.2.2 or higher).
* an x86\_64 or armel Linux host to compile Xen kernels, or FreeBSD, OpenBSD or
  MacOS X for the userlevel version.

**Docker image**

There is a maintained Docker image at
[unikernel/mirage](https://hub.docker.com/r/unikernel/mirage/).
You can also use the Dockerfile in this repository:

```
docker build -t mirage .
docker run -v <your-source>:/src opam config exec -- mirage
```

### Using `mirage`

There are two stages to using `mirage`:

* a *configure* phase where necessary code is generated and dependencies are determined.
* an optional *depends* phase where OPAM package dependencies are satisfied.
* a *build* phase where the compiler and any support scripts are run.

You can find documentation, walkthroughs and tutorials over on the
[MirageOS website](https://mirage.io).
The [install instructions](https://mirage.io/wiki/install)
are a good place to begin!
