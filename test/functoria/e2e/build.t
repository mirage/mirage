Build an application.

  $ ./test.exe configure --file app/config.ml
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ make build
  dune build --profile release --root . app/dist
  Your unikernel binary is now ready in app/dist/noop
  Execute the binary using solo5-hvt, solo5-spt, xl, ...
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
  dune-workspace.config
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
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ make build
  dune build --profile release --root . app/dist
  Your unikernel binary is now ready in app/dist/toto
  Execute the binary using solo5-hvt, solo5-spt, xl, ...
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
  dune-workspace.config
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
