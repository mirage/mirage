Build an application.

  $ ./test.exe configure --file app/config.ml
  $ make build
  dune build --profile release --root .
  $ ls -a app/
  .
  ..
  app.ml
  config.ml
  dist
  dune
  dune.build
  dune.config
  main.exe
  test
  $ ls -a app/test
  .
  ..
  context
  main.ml
  noop.opam
  vote
  warn_error
  $ ./app/main.exe --required=foo
  Success: hello=Hello World! arg=-
  $ ./test.exe clean --file app/config.ml
  $ ls -a app/
  .
  ..
  app.ml
  config.ml

Test `--output`:

  $ ./test.exe configure --file app/config.ml -o toto
  $ make build
  dune build --profile release --root .
  $ ls -a app/
  .
  ..
  app.ml
  config.ml
  dist
  dune
  dune.build
  dune.config
  test
  toto.exe
  $ ls -a app/test
  .
  ..
  context
  noop.opam
  toto.ml
  vote
  warn_error
  $ ./app/toto.exe --required=foo
  Success: hello=Hello World! arg=-
  $ ./test.exe clean --file app/config.ml
  $ ls -a app/
  .
  ..
  app.ml
  config.ml
