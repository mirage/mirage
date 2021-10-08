Build an application.

  $ ./test.exe configure --file app/config.ml
  $ ./test.exe build -v --file app/config.ml
  test.exe: [INFO] run: build:
                        { "context" = ;
                          "config_file" = app/config.ml;
                          "output" = None;
                          "dry_run" = false }
  test.exe: [INFO] Generating: app/test/dune-workspace.config (base)
  test.exe: [INFO] Generating: dune-project (base)
  test.exe: [INFO] Generating: app/dune.config (base)
  config.exe: [INFO] reading cache app/test/context
  config.exe: [INFO] Name       noop
                     Keys      
                       hello=Hello World! (default),
                       vote=cat (default),
                       warn_error=false (default)
  config.exe: [INFO] dune build --root .
  $ ls -a app/
  .
  ..
  app.ml
  config.ml
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
  key_gen.ml
  main.ml
  noop-monorepo.opam
  noop-switch.opam
  vote
  warn_error
  $ ./app/main.exe
  Success: vote=cat hello=Hello World!
  $ ./test.exe clean --file app/config.ml
  $ ls -a app/
  .
  ..
  app.ml
  config.ml

Test `--output`:

  $ ./test.exe configure --file app/config.ml -o toto
  $ ./test.exe build -v --file app/config.ml
  test.exe: [INFO] run: build:
                        { "context" = ;
                          "config_file" = app/config.ml;
                          "output" = None;
                          "dry_run" = false }
  test.exe: [INFO] Generating: app/test/dune-workspace.config (base)
  test.exe: [INFO] Generating: dune-project (base)
  test.exe: [INFO] Generating: app/dune.config (base)
  config.exe: [INFO] reading cache app/test/context
  config.exe: [INFO] Name       noop
                     Keys      
                       hello=Hello World! (default),
                       vote=cat (default),
                       warn_error=false (default)Output     toto
  config.exe: [INFO] dune build --root .
  $ ls -a app/
  .
  ..
  app.ml
  config.ml
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
  key_gen.ml
  noop-monorepo.opam
  noop-switch.opam
  toto.ml
  vote
  warn_error
  $ ./app/toto.exe
  Success: vote=cat hello=Hello World!
  $ ./test.exe clean --file app/config.ml
  $ ls -a app/
  .
  ..
  app.ml
  config.ml
