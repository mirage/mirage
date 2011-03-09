
Mirage has been tested on:

* Debian Squeeze x86_64 and x86_32
* Ubuntu Lucid 10.04 x86_64
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
* Js_of_ocaml from http://ocsigen.org/js_of_ocaml/install (optional)

Debian Squeeze and Ubuntu are still at 3.11, but you can grab the latest
packages from: http://ocaml.debian.net/debian/ocaml-3.12.0/

Then: apt-get install ocaml-findlib camlp4-extra ocaml-native-compilers

### Ubuntu

    sudo apt-get remove ocaml-findlib camlp4-extra ocaml-native-compilers
    sudo apt-get autoremove

There are then package conflicts with the following, which must be
downloaded and installed separately:

    ncurses-bin_5.7+20100626-0ubuntu1_amd64.deb
    libncurses5-dev_5.7+20100626-0ubuntu1_amd64.deb
    libncurses5_5.7+20100626-0ubuntu1_amd64.deb

    sudo dpkg --install ~/libncurses5-dev_5.7+20100626-0ubuntu1_amd64.deb 
    sudo dpkg --install ~/ncurses-bin_5.7+20100626-0ubuntu1_amd64.deb 
    sudo dpkg --install ~/libncurses5-dev_5.7+20100626-0ubuntu1_amd64.deb 
    sudo apt-get install ocaml-findlib camlp4-extra ocaml-native-compilers ocaml-nox 

The necessary GPG key must be installed to use the package source for
the latest OCaml versions:

    gpg -a --export 49881AD3 > glondu.gpg
    apt-key add glondu.gpg

Then add the following to `/etc/apt/sources.list`

    deb     http://ocaml.debian.net/debian/ocaml-3.12.0 sid main
    deb-src http://ocaml.debian.net/debian/ocaml-3.12.0 sid main

And finally execute apt-get update:

    sudo apt-get update
    sudo apt-get upgrade

To install tuntap device, required for unix-direct:

    sudo modprobe tun
    

All-in-one
----------

    make PREFIX=<location> all install


Tools
-----

This installs the build tools and syntax extensions into the install PREFIX.

    make PREFIX=<location> tools

The tools include the `mir-unix-*` and `mir-xen` build wrappers and the
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

    mir-unix-direct sleep.bin

output will be in `_build/sleep.bin`

Build a Xen kernel:

    mir-xen sleep.xen

output will be in `_build/sleep.{bin,xen}`, and you can boot it up
in Xen with a config file like:

    $ cat > sleep.cfg
    name="sleep"
    memory=1024
    kernel="sleep.xen"
    <control-d>
    $ sudo xm create -c sleep.cfg

This runs a simple interlocking sleep test which tries out the
console and timer support for the various supported platforms.

Note that the `kernel` variable only accepts an absolute path or the
name of a file in the current directory.


Network
-------

Mirage networking is present in the Net module and can compile in two modes: 

A 'direct' mode that works from the Ethernet layer (the OS.Ethif
module). On Xen, this is the virtual Ethernet driver, and on UNIX
this requires the `tuntap` interface.

A subset of the Net modules (Flow and Manager) are available in
'socket' mode under UNIX. This maps the Flow interface onto POSIX
sockets, enabling easy comparison with normal kernels.

There are two echo servers available in:

* `tests/net/flow` 
* `tests/net/flow_udp`

You can compile these with:

    $ mir-unix-socket echo.bin
    $ ./_build/echo.bin

    $ mir-unix-direct echo.bin
    $ sudo ./_build/echo.bin

    $ mir-xen echo.xen
    # boot the kernel in ./_build/echo.xen
