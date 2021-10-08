Make sure that clean remove everything:

  $ ./test.exe configure --file app/config.ml
  $ ls -a app
  .
  ..
  app.ml
  config.ml
  dune
  dune.build
  dune.config
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
  $ ./test.exe clean -v --file app/config.ml
  test.exe: [INFO] run: clean:
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
  test.exe: [INFO] Skipped ./app
  test.exe: [INFO] Skipped ./clean.t
  test.exe: [INFO] Skipped ./help.exe
  test.exe: [INFO] Skipped ./lib
  test.exe: [INFO] Skipped ./test.exe
  $ ls -a app
  .
  ..
  app.ml
  config.ml

Check that clean works with `--output`:

  $ ./test.exe configure --file app/config.ml --output=toto
  $ ls -a app
  .
  ..
  app.ml
  config.ml
  dune
  dune.build
  dune.config
  test
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
  $ ./test.exe clean -v --file app/config.ml
  test.exe: [INFO] run: clean:
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
  test.exe: [INFO] Skipped ./app
  test.exe: [INFO] Skipped ./clean.t
  test.exe: [INFO] Skipped ./help.exe
  test.exe: [INFO] Skipped ./lib
  test.exe: [INFO] Skipped ./test.exe
  $ ls -a app
  .
  ..
  app.ml
  config.ml
