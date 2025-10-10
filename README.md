<div align="center">
  <a href="https://mirageos.org">
    <img src="./logo.svg" alt="MirageOS logo"/>
  </a>
  <br />
  <strong>Build Unikernels in OCaml</strong>
</div>

<div align="center">
<br />

[![OCaml-CI Build Status](https://img.shields.io/endpoint?url=https%3A%2F%2Focaml.ci.dev%2Fbadge%2Fmirage%2Fmirage%2Fmain&logo=ocaml&style=flat-square)](https://ocaml.ci.dev/github/mirage/mirage)
[![docs](https://img.shields.io/badge/doc-online-blue.svg)](https://mirage.github.io/mirage/)

</div>

<hr />

<div align="center">
  <em>
    MirageOS is a library operating system that constructs secure,
    performant and resource-efficient unikernels.
  </em>
</div>

## About

MirageOS is a library operating system that constructs unikernels for
secure, high-performance network applications across various cloud
computing and mobile platforms. Developers can write code on a
traditional OS such as Linux or macOS. They can then compile their
code into a fully-standalone, specialised unikernel that runs under
the Xen or KVM hypervisors and lightweight hypervisors like FreeBSD's
BHyve, OpenBSD's VMM. These unikernels can deploy on public clouds,
like Amazon's Elastic Compute Cloud and Google Compute Engine, or
private deployments.

The most up-to-date documentation can be found at the
[homepage](https://mirageos.org). The site is [a self-hosted
unikernel](https://github.com/mirage/mirage-www).  Simpler [skeleton
applications](https://github.com/mirage/mirage-skeleton) are also
available online.  MirageOS unikernels repositories are also available
[here](https://github.com/roburio/unikernels) or
[there](https://github.com/tarides/unikernels).

### This repository

This repository contains the `mirage` command-line tool to create and
deploy applications with MirageOS. This tool wraps the specialised
configuration and build steps required to build MirageOS on all the
supported targets.

**Local install**

You will need the following:

* a working [OCaml](https://ocaml.org) compiler (4.13.0 or higher).
* the [Opam](https://opam.ocaml.org) source package manager (2.1.0 or higher).
* an x86\_64 or armel Linux host to compile Xen kernels, or FreeBSD, OpenBSD or
  MacOS X for the solo5 and userlevel versions.

Then run:

```
$ opam install mirage
$ mirage --version
```

This should display at least version `4.0.0`.

### Using `mirage`

There are multiple stages to using `mirage`:

* write `config.ml` to describe the components of your applications;
* call `mirage configure` to generate the necessary code and metadata;
* optionally call `make depends` to install external dependencies and
  download Opam packages in the current [dune](https://dune.build/) workspace.
* call `dune build` to build a unikernel.

You can find documentation, walkthroughs and tutorials over on the
[MirageOS website](https://mirageos.org).
The [install instructions](https://mirageos.org/wiki/install)
are a good place to begin!
