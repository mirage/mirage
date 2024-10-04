Configure the project for Unix:

  $ mirage configure -t unix 2>/dev/null

The command succeeded and created a number of files. It produced a load of
warnings, but matching on the warnings given different compiler versions with
ever slightly different output is not worth it.

  $ ls -a
  .
  ..
  Makefile
  _build
  config.ml
  dist
  dune
  dune-project
  dune-workspace
  dune.build
  dune.config
  mirage
