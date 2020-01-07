let () = Alcotest.run "functoria" [
    "cli"    , Test_cli.suite;
    "package", Test_package.suite;
    "impl"   , Test_impl.suite;
  ]
