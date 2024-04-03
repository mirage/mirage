Test that `describe` works as expected:

  $ ./test.exe describe --file app/config.ml
  Name       noop
  Keys       vote=cat (default),
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
  Name       noop
  Keys       vote=cat (default),
             warn_error=false (default)
  Libraries  cmdliner, fmt, mirage-runtime.functoria
  Packages   cmdliner { ?monorepo }, fmt { ?monorepo },
    mirage-runtime { ?monorepo }
