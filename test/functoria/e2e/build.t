Build an application.

  $ ./test.exe configure --file app/config.ml
  $ ./test.exe build -v --file app/config.ml
  test.exe: [INFO] run: build:
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
  config.exe: [INFO] Building: app/config.ml
  $ ls -a app/
  .
  ..
  app.ml
  config.ml
  dune
  dune.build
  dune.config
  key_gen.ml
  main.exe
  main.ml
  test.context
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
  test.exe: [INFO] Compiling: app/config.ml
  config.exe: [INFO] Name       noop
                     Keys      
                       hello=Hello World! (default),
                       vote=cat (default),
                       warn_error=false (default)Output     toto
  config.exe: [INFO] Building: app/config.ml
  $ ls -a app/
  .
  ..
  app.ml
  config.ml
  dune
  dune.build
  dune.config
  key_gen.ml
  test.context
  toto.exe
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
