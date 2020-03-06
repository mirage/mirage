let t = { Mirage_runtime.name = "foo"; libraries = [ "bar" ]; packages = [] }

let test_info () = Alcotest.(check string) "name" t.name "foo"

let () = Alcotest.run "mirage" [ ("basic", [ ("info", `Quick, test_info) ]) ]
