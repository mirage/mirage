Useful build targets:

Given an input foo.ml:

    $ mir-unix-socket foo.pp.ml

...will post-process the file with all the syntax extensions, and output the result in `_build/foo.pp.ml`. This is very useful to inspect the actual OCaml code being compiled after syntax extensions such as LWT or COW have been applied.

