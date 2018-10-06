let triple a b c =
  let open Alcotest in
  let eq (a1, b1, c1) (a2, b2, c2) =
    equal a a1 a2
    && equal b b1 b2
    && equal c c1 c2
  in
  let pp fmt (va, vb, vc) =
    Format.fprintf
      fmt
      "(%a, %a, %a)"
      (pp a) va
      (pp b) vb
      (pp c) vc
  in
  testable pp eq

let testable t =
  let open Alcotest in
  let rresult_msg = testable (Rresult.R.pp_msg) (=) in
  triple
    (result t rresult_msg)
    (list (module Fpath))
    (list string)

let test_exists =
  let test ~path ~files ~expected ~expected_log =
    let got = Mirage_job.dry_run ~files (Mirage_job.exists path) in
    Alcotest.check (testable Alcotest.bool) "exists" (expected, files, expected_log) got
  in
  [ "exists (true)", `Quick, (fun () ->
    let path = Fpath.v "path" in
    test
      ~path
      ~files:[path]
      ~expected:(Ok true)
      ~expected_log:["Exists? path -> true"]
    )
  ; "exists (false)", `Quick, (fun () ->
    let path = Fpath.v "path" in
    let other_path = Fpath.v "other_path" in
    test
      ~path
      ~files:[other_path]
      ~expected:(Ok false)
      ~expected_log:["Exists? path -> false"]
    )
  ]

let test_delete =
  let test ~path ~files ~expected =
    let got = Mirage_job.dry_run ~files (Mirage_job.delete path) in
    Alcotest.check (testable Alcotest.unit) __LOC__ expected got
  in
  [ "delete (file exists)", `Quick, (fun () ->
    let path = Fpath.v "path" in
    let other_path = Fpath.v "other_path" in
    test
      ~path
      ~files:[path; other_path]
      ~expected:(Ok (), [other_path], ["Delete path (ok)"])
    )
  ; "delete (file does not exist)", `Quick, (fun () ->
    let path = Fpath.v "path" in
    let other_path = Fpath.v "other_path" in
    let files = [other_path] in
    test
      ~path
      ~files
      ~expected:
        ( Error (Rresult.R.msg "File does not exist")
        , files
        , ["Delete path (error)"]
        )
    )
  ]

let test_run_cmd =
  let test ~cmd ~expected ~expected_log =
    let files = [] in
    let got = Mirage_job.dry_run ~files (Mirage_job.run_cmd cmd) in
    Alcotest.check (testable Alcotest.unit) __LOC__ (expected, files, expected_log) got
  in
  [ "run_cmd always fails", `Quick, (fun () ->
      test
        ~cmd:(Bos.Cmd.v "some-command")
        ~expected:(Error (Rresult.R.msg "run_cmd is not supported"))
        ~expected_log:["Run: some-command"]
    )
  ]

let test_write =
  let test ~path ~files ~contents ~expected =
    let got = Mirage_job.dry_run ~files (Mirage_job.write_file path contents) in
    Alcotest.check (testable Alcotest.unit) __LOC__ expected got
  in
  [ "write to nonexisting file", `Quick, (fun () ->
    let path = Fpath.v "path" in
    let contents = "contents" in
    test
      ~path
      ~files:[]
      ~contents
      ~expected:(Ok (), [path], ["Write to path (8 bytes)"])
    )
  ; "write to existing file", `Quick, (fun () ->
    let path = Fpath.v "path" in
    let contents = "contents" in
    test
      ~path
      ~files:[path]
      ~contents
      ~expected:(Ok (), [path], ["Write to path (8 bytes)"])
    )
  ]

let test_bind =
  [ "sequence", `Quick, (fun () ->
    let path1 = Fpath.v "path1" in
    let path2 = Fpath.v "path2" in
    let got =
      Mirage_job.dry_run ~files:[path1; path2] @@
      Mirage_job.bind
      (Mirage_job.delete path1)
      ~f:(fun () -> Mirage_job.delete path2)
    in
    Alcotest.check
      (testable Alcotest.unit)
      __LOC__
      ( Ok ()
      , []
      , [ "Delete path1 (ok)"
        ; "Delete path2 (ok)"
        ]
      )
      got
    )
  ; "sequence after error", `Quick, (fun () ->
    let path1 = Fpath.v "path1" in
    let path2 = Fpath.v "path2" in
    let got =
      Mirage_job.dry_run ~files:[path2] @@
      Mirage_job.bind
      (Mirage_job.delete path1)
      ~f:(fun () -> Mirage_job.delete path2)
    in
    Alcotest.check
      (testable Alcotest.unit)
      "sequence_error"
      ( Rresult.R.error_msg "File does not exist"
      , [path2]
      , ["Delete path1 (error)"]
      )
      got
    )
  ; "bind passes the correct value to caller code", `Quick, (fun () ->
    let value = 5 in
    let got =
      Mirage_job.dry_run ~files:[] @@
      Mirage_job.bind
      (Mirage_job.return value) 
      ~f:(fun got_value ->
        Alcotest.check Alcotest.int "value matches" value got_value;
        Mirage_job.return ()
      )
    in
    Alcotest.check (testable Alcotest.unit) "bind" (Ok (), [], []) got
    )
  ]

let test_with_fmt =
  let test ~contents ~expected =
    let files = [] in
    let mode = Some 0o755 in
    let path = Fpath.v "path" in
    let purpose = "PURPOSE" in
    let called = ref false in
    let got =
      Mirage_job.dry_run ~files @@
      Mirage_job.with_out ~mode ~path ~purpose
      (fun fmt ->
        called := true;
        Format.fprintf fmt "%s" contents
      )
    in
    Alcotest.check
      (testable Alcotest.unit)
      __LOC__
      ( expected
      , [path]
      , ["Write (fmt) to path (mode: 0755, purpose: PURPOSE)"]
      )
      got;
    Alcotest.check Alcotest.bool "k was called" true !called
  in
  [ "write", `Quick, (fun () ->
    let contents = "contents" in
    test ~contents ~expected:(Ok ())
    )
  ]

let test_dry_run =
  List.concat
  [ test_exists
  ; test_delete
  ; test_run_cmd
  ; test_write
  ; test_bind
  ; test_with_fmt
  ]

let tests =
  [ ("dry_run", test_dry_run)
  ]

let () = Alcotest.run "Mirage_job" tests
