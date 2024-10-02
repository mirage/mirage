Configure the project for Unix:

  $ mirage configure -t unix
  mirage: [WARNING] Skipping version check, since our_version is not watermarked
  File "config.ml", line 3, characters 10-14:
  3 | let eth = etif default_network
                ^^^^
  Alert deprecated: Mirage.etif
  Deprecated. Use [ethif] instead.
  File "config.ml", line 3, characters 10-14:
  3 | let eth = etif default_network
                ^^^^
  Alert deprecated: Mirage.etif
  Deprecated. Use [ethif] instead.
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
