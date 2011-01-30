Mirage has been tested on:

* Debian Squeeze x86_64 and x86_32
* MacOS X 10.6 Snow Leopard x86_64
* MacOS X 10.5 Snow Leopard x86_32

To build it, you must first:

1. Install the basic toolchain
2. Build the tools
3. Build the core libraries

Toolchain
---------

You need to have the following installed and available on your PATH:

* OCaml 3.12.0
* OCamlfind

Debian Squeeze and Ubuntu are still at 3.11, but you can grab the latest
packages from: http://ocaml.debian.net/debian/ocaml-3.12.0/

Then: apt-get install ocaml-findlib camlp4-extra ocaml-native-compilers

Tools
-----

This installs the build tools and syntax extensions into the install PREFIX.

    make PREFIX=<location> tools

The tools include the `mir-unix` and `mir-xen` build wrappers and the
MPL protocol specification meta-compiler.

Libraries
---------

    make && make install

This will build the OCaml libraries and the Xen custom runtime, if
appropriate for the build platform.  You require 64-bit Linux to
compile up Xen binaries (32-bit will not work).

Build an application
--------------------

Mirage uses `ocamlbuild` to build applications, with the `mir`
script providing a thin wrapper to install a custom plugin to deal
with the various backends.

To try out basic functionality, do `cd tests/basic/sleep`.

Build a UNIX binary:

    mir-unix sleep.bin

output will be in `_build/sleep.bin`

Build a Xen kernel:

    mir-xen sleep.xen

output will be in `_build/sleep.{bin,xen}`, and you can boot it up
in Xen with a config file like:

    $ cat > sleep.cfg
    name="sleep"
    memory=1024
    kernel="_build/sleep.bin"
    <control-d>
    $ sudo xm create -c sleep.cfg

This runs a simple interlocking sleep test which tries out the
console and timer support for the various supported platforms.

Coming soon: I/O :-)
