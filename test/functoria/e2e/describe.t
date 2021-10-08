Test that `describe` works as expected:

  $ ./test.exe describe --file app/config.ml
  Name       noop
  Keys      
    hello=Hello World! (default),
    vote=cat (default),
    warn_error=false (default)
  $ ./test.exe describe -v --file app/config.ml
  test.exe: [INFO] run: describe:
                        { "args" =
                           { "context" = ;
                             "config_file" = app/config.ml;
                             "output" = None;
                             "dry_run" = false };
                          "dotcmd" = "xdot";
                          "dot" = false;
                          "eval" = None }
  test.exe: [INFO] Generating: app/test/dune-workspace.config (base)
  test.exe: [INFO] Generating: dune-project (base)
  test.exe: [INFO] Generating: app/dune.config (base)
  Name       noop
  Keys      
    hello=Hello World! (default),
    vote=cat (default),
    warn_error=false (default)Libraries  fmt, functoria-runtime
  Packages   fmt, functoria-runtime
