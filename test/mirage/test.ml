open Mirage

let t = kv_ro @-> job

let test_typ () =
  Alcotest.(check string) "pp" (Fmt.to_to_string Mirage.Type.pp t) "(_ -> _)"

let () = Alcotest.run "mirage" [ ("basic", [ ("pp", `Quick, test_typ) ]) ]
