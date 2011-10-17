ocp-pack
========

  Pack a list of sources in the same manner as the -pack option.

Usage:
------
ocp-pack -o target.ml [options] files

 Interesting options:
 --------------------
 -mli : generate a .mli file too. As the signature is provided, and generated
      from found .mli files, only units with corresponding .mli files will
      appear.
 -rec : use recursive modules (all .ml files should have a corresponding .mli
         file)
 -pack-functor <modname> : generate a functor of name <Modname>
 -functor <filename.mli> : specify the signature argument of the functor.


ocp-split
=========

  Split a packed annot file into individual annot files.

Usage:
------

ocp-split source.annot
