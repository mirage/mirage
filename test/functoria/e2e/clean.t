Make sure that clean remove everything:

  $ ./test.exe configure --file app/config.ml
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ ls -a app
  .
  ..
  app.ml
  config.ml
  dist
  dune
  dune.build
  dune.config
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
                     Keys       vote=cat (default),
                                warn_error=false (default)
  test.exe: [INFO] Skipped ./app
  test.exe: [INFO] Skipped ./context
  test.exe: [INFO] Skipped ./errors
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
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ ls -a app
  .
  ..
  app.ml
  config.ml
  dist
  dune
  dune.build
  dune.config
  test
  $ ls -a app/test
  .
  ..
  context
  dune-workspace.config
  noop.opam
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
                     Keys       vote=cat (default),
                                warn_error=false (default)
                     Output     toto
  test.exe: [INFO] Skipped ./app
  test.exe: [INFO] Skipped ./context
  test.exe: [INFO] Skipped ./errors
  test.exe: [INFO] Skipped ./help.exe
  test.exe: [INFO] Skipped ./lib
  test.exe: [INFO] Skipped ./test.exe
  $ ls -a app
  .
  ..
  app.ml
  config.ml
