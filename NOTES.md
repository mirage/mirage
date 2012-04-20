## Build targets

The `mir-build` script is a wrapper over OCamlbuild, which symlinks in our plugin (from `scripts/myocamlbuild`).

These must be run from the `lib/` directory only, and will not work in subdirectories.

Given an input foo.ml:

    $ mir-build foo.pp.ml

...will post-process the file with all the syntax extensions, and output the result in `_build/foo.pp.ml`. This is very useful to inspect the actual OCaml code being compiled after syntax extensions such as LWT or COW have been applied.

    $ mir-build foo.inferred.mli

...will generate the default .mli for a given .ml file (useful as a skeleton). It will be in `_build/foo.inferred.mli` and can be copied into the source directory and edited from there.

## Test suite targets

These are useful to automatically run Xen kernels using `mir-run`.

    $ cd regress
   
The general form is `<dir>/<base filename>.<backend>.exec` to run them.
 
    # run the heads-and-tails test.
    $ mir-build lwt/heads1.xen.exec
    $ mir-build lwt/heads1.unix-socket.exec
    $ cat _build/lwt/heads1.unix-socket.exec

To build the raw kernel directly, prepend the backend as a virtual directory:

    $ mir-build xen/lwt/heads1.xen
    $ mir-build unix-direct/lwt/heads1.bin

NOTE: if you use the automatic target, it will not have any VIFs or storage. Look at the `mir-run` script for arguments to plug in a VIF or block device or K/V store. E.g. to run the TCP echo test:

    $ mir-build xen/net/tcp_echo.xen
    $ mir-run -b xen _build/xen/net/tcp_echo.xen -vif br0

This particular test defaults to `10.0.0.2` (look in the source), so you bridge will be `10.0.0.1` and you should be able to telnet to `10.0.0.2 55555`.

In the build system, Xen kernels have a `.bin` extension, and all UNIX binaries are `.bin`.

You can also define a suite of tests and run them all:

    # run a suite of tests, as listed in .suite
    $ mir-build lwt.run
    $ cat _build/lwt.run

## Bytecode targets

For the UNIX targets, there are 3 targets (by the filename extension):

* `.bin`: native code
* `.bcbin`: bytecode as an embedded callback
* `.bcxbin`: bytecode with deadcode-elimination via ocamlclean [1]

For Xen, there is a bytecode (that requires ocamlclean) and native code:

* `.xen`: native code microkernel
* `.bcxen`: bytecode microkernel with deadcode-elimination via ocamlclean [1]

Note that ocamlclean can be quite slow (minutes) for larger applications,
hence it isnt done by default for the bytecode target.

[1] Modified to support Mirage, at http://github.com/avsm/ocamlclean
