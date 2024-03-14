Check that configure generates the file in the right dir when `--file`
is passed:

  $ ./test.exe configure -v --file app/config.ml
  test.exe: [INFO] run: configure:
                        { "args" =
                           { "context" = ;
                             "config_file" = app/config.ml;
                             "output" = None;
                             "dry_run" = false };
                          "depext" = true }
  test.exe: [INFO] Generating: app/test/dune-workspace.config (base)
  test.exe: [INFO] Generating: dune-project (base)
  test.exe: [INFO] Generating: app/dune.config (base)
  test.exe: [INFO] Preserving arguments in app/test/context:
                   [|"./test.exe"; "configure"; "-v"; "--file";
                     "app/config.ml"|]
  test.exe: [INFO] Set-up config skeleton.
  config.exe: [INFO] reading cache app/test/context
  config.exe: [INFO] Name       noop
                     Keys       vote=cat (default),
                                warn_error=false (default)
  config.exe: [INFO] Generating: noop.opam (opam)
  config.exe: [INFO] in dir { "context" = ;
                              "config_file" = app/config.ml;
                              "output" = None;
                              "dry_run" = false }
  config.exe: [INFO] Generating: main.ml (main file)
  config.exe: [INFO] Generating: dune.build (dune.build)
  config.exe: [INFO] Generating: dune-workspace (dune-workspace)
  config.exe: [INFO] Generating: dune-project (dune-project)
  config.exe: [INFO] Generating: dune (dune.dist)
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
  $ ls -a app/test
  .
  ..
  context
  dune-workspace.config
  main.ml
  noop.opam
  vote
  warn_error
  $ ./test.exe clean --file app/config.ml

Check that configure create the correct context file:

  $ ./test.exe configure --file=app/config.ml
  $ cat app/test/context
  configure
  --file=app/config.ml
  $ rm -rf custom_build_

  $ ./test.exe configure --file=app/config.ml
  $ cat app/test/context
  configure
  --file=app/config.ml
  $ ./test.exe clean --file=app/config.ml

Check that `test help configure` and `test configure --help` have the
same output.

  $ ./test.exe help configure --file=app/config.ml --help=plain > h1
  $ ./test.exe configure --help=plain --file=app/config.ml > h2
  $ ./help.exe diff h1 h2

Check that `test help configure` works when no config.ml file is present.

  $ ./test.exe configure --help=plain > h0
  $ ./help.exe show h0 SYNOPSIS | xargs
  test configure [OPTION]…

Check that errors are reported correcty:

  $ ./test.exe configure a b c --file=app/config.ml
  test: too many arguments, don't know what to do with 'a', 'b', 'c'
  Usage: test configure [OPTION]…
  Try 'test configure --help' or 'test --help' for more information.
  [1]
