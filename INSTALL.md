Mirage has been tested on Debian Squeeze, Ubuntu Lucid and MacOS X 10.6. To compile the Xen backend, you *must* have a 64-bit Linux host.  32-bit is not supported at this time.

# Requirements

You need to have the following installed and available on your `PATH`:

* [OCaml](http://www.ocaml.org) 3.12.0
* (optional) [Js_of_ocaml](http://ocsigen.org/js_of_ocaml/install)

# Installation

Pick a location you want to install the binaries and add `$PREFIX/bin` to your `PATH`. The default `PREFIX` is `~/mir-inst` which does not require super-user access.

Then run

```
make PREFIX=<location>
make install
```

The installation has the UNIX and Xen custom runtimes, if appropriate for the build platform.  You require 64-bit Linux to compile up Xen binaries (32-bit will not work).

# IDE integration

### Emacs

Mirage comes with a slightly modified version of the `caml-mode` to dispay type information. In order to install it, you can run

```
make install-el
```

### Vim

You will need the latest version [ocaml-annot](https://github.com/avsm/ocaml-annot) (>= 0.9.1), to be able to display type information for your Mirage projects.

