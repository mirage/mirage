## Build targets

These must be run from the `lib/` directory only, and will not work in subdirectories.

Given an input foo.ml:

    $ mir-build foo.pp.ml

...will post-process the file with all the syntax extensions, and output the result in `_build/foo.pp.ml`. This is very useful to inspect the actual OCaml code being compiled after syntax extensions such as LWT or COW have been applied.

    $ mir-build foo.inferred.mli

...will generate the default .mli for a given .ml file (useful as a skeleton). It will be in `_build/foo.inferred.mli` and can be copied into the source directory and edited from there.

## Test suite targets

    $ cd regress
    
    # run a single test, as listed in a .spec file
    $ ocamlbuild lwt/heads1.exec
    $ cat _build/lwt/heads1.exec
    
    # run a suite of tests, as listed in .suite
    $ ocamlbuild lwt.run
    $ cat _build/lwt.run

