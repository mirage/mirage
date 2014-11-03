# Mirage

Mirage is a programming framework for constructing secure, high-performance
network applications across a variety of cloud computing and mobile platforms.
Code can be developed on a normal OS such as Linux or MacOS X, and then
compiled into a fully-standalone, specialised unikernel that runs under the Xen
hypervisor.  Since Xen powers most public cloud computing infrastructure such
as Amazon EC2, this lets your servers run more cheaply, securely and finer
control than with a full software stack.

The most up-to-date documentation can be found at the homepage, at
<http://www.openmirage.org>.  The site is self-hosted and a useful example,
available at <https://github.com/mirage/mirage-www>. Simpler skeleton
applications are found at <https://github.com/mirage/mirage-skeleton>.

This repository includes:

* a commmand-line tool to create and deploy applications with Mirage.
* in `types/`, a library of type signatures that compliant applications use.

There are several diverse backends in Mirage that require rather specialised
build steps (from Javascript to Xen unikernels), and this complexity is
wrapped up in the tool.

To work with Mirage, you'll need the following prerequisites installed:

* a working [OCaml](http://ocaml.org) compiler (4.01.0 or higher).
* the [OPAM](https://opam.ocaml.org) source package manager (1.2.0 or higher).
* an x86\_64 or armel Linux host to compile Xen kernels, or FreeBSD, OpenBSD or MacOS X
  for the userlevel version.

There are three stages to using `mirage`:

* a *configuration* phase where OPAM package dependencies are
  satisfied.

* a *build* phase where the compiler and any support scripts are run.

* a *run* phase where `mirage` spawns and tracks the progress of the
  deployment (e.g. as a UNIX process or a Xen kernel).

## Configuration files

`mirage` currently uses a configuration file to build a Mirage unikernel.
While we're documenting it all, please see the `lib_test` directory in
this repository for the regression examples.  The latest instructions are
also to be found at <http://openmirage.org/docs>

## Configuring Mirage Applications

Provided that one and only one file of name `<foo>.conf` (where
`<foo>` can be any string) is present in the current working
directory, the command:

```
mirage configure
```

will configure your project. It will generate a `Makefile` and
`main.ml` with the appropriate boilerplate for your chosen
platform.

To configure for the unix-direct target (using tap interfaces), do:

```
mirage configure --unix
```

To build for the xen target, do:

```
mirage configure --xen
```

Once configuration is complete, you can install the OPAM packages required by
this unikernel by:

```
make depend
```

## Building Mirage Applications

The command:

```
mirage build
```

will build your project. Likewise, you can use the `--unix` or `--xen`
switches to build for a particular target.

## Running Mirage Applications

The command:

```
mirage run # [--unix or --xen]
```

will run the unikernel on the selected backend.

* Under the unix-direct backend (`--unix`), `mirage` sets up a virtual
  interface (tap) is passes its fd to the unikernel that will use it to
  perform networking operations.

* Under the xen backend (`--xen`), `mirage` creates a xl configuration
  file and uses `xl` to run the unikernel locally. Xen has to be
  installed and running on the machine.

### Compiling to Xen and deploying to the cloud

In order to deploy a Mirage unikernel to Amazon EC2, you need to
install the AWS tools on your machine, build a unikernel with the
`--xen` option and then use the `ec2.sh` script (in directory
`script`) in order to register you kernel with AWS. Then you can start
your kernel with the web interface to AWS or any other mean AWS
provides to start EC2 instances.
