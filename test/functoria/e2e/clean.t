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
  key_gen.ml
  main.ml
  test.context
  $ ./test.exe clean -v --file app/config.ml
  test.exe: [INFO] run: clean:
                        { "context" = ;
                          "config_file" = app/config.ml;
                          "output" = None;
                          "dry_run" = false }
  test.exe: [INFO] Compiling: app/config.ml
  config.exe: [INFO] Name       noop
                     Keys      
                       hello=Hello World! (default),
                       vote=cat (default),
                       warn_error=false (default)
  config.exe: [INFO] Cleaning: app/config.ml
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
  key_gen.ml
  test.context
  toto.ml
  $ ./test.exe clean -v --file app/config.ml
  test.exe: [INFO] run: clean:
                        { "context" = ;
                          "config_file" = app/config.ml;
                          "output" = None;
                          "dry_run" = false }
  test.exe: [INFO] Compiling: app/config.ml
  config.exe: [INFO] Name       noop
                     Keys      
                       hello=Hello World! (default),
                       vote=cat (default),
                       warn_error=false (default)Output     toto
  config.exe: [INFO] Cleaning: app/config.ml
  $ ls -a app
  .
  ..
  app.ml
  config.ml
