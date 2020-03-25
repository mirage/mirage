let () =
  Alcotest.run "functoria"
    [
      ("cli", Test_cli.suite);
      ("package", Test_package.suite);
      ("graph", Test_graph.suite);
      ("action", Test_action.suite);
      ("key", Test_key.suite);
    ]
