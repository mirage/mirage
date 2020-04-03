open Functoria
open Action.Infix

let triple a b c =
  let open Alcotest in
  let eq (a1, b1, c1) (a2, b2, c2) =
    equal a a1 a2 && equal b b1 b2 && equal c c1 c2
  in
  let pp fmt (va, vb, vc) =
    Fmt.pf fmt "(%a, %a, %a)" (pp a) va (pp b) vb (pp c) vc
  in
  testable pp eq

let fpath = Alcotest.testable Fpath.pp Fpath.equal

let testable t =
  let open Alcotest in
  let rresult_msg = testable Rresult.R.pp_msg ( = ) in
  let env = testable Action.pp_env Action.eq_env in
  triple (result t rresult_msg) env (list string)

let file = "<file>"

let dir = "<DIR>"

let error e = Error (`Msg e)

let ( ! ) files = Action.env ~files:(`Files files) ()

let path = Fpath.v "path"

let other_path = Fpath.v "other_path"

let test_bind () =
  let got =
    Action.dry_run
      ~env:![ (path, file); (other_path, file) ]
      (Action.rm path >>= fun () -> Action.rm other_path)
  in
  Alcotest.check (testable Alcotest.unit) "sequence"
    (Ok (), ![], [ "Rm path (removed)"; "Rm other_path (removed)" ])
    got;

  let got =
    Action.dry_run
      ~env:![ (other_path, dir) ]
      (Action.rm path >>= fun () -> Action.rm other_path)
  in
  Alcotest.check (testable Alcotest.unit) "sequence after error"
    ( error "other_path is a directory",
      ![ (other_path, dir) ],
      [ "Rm path (no-op)"; "Rm other_path (error)" ] )
    got;

  let got =
    let value = 5 in
    Action.dry_run ~env:![]
      ( Action.ok value >>= fun got_value ->
        Alcotest.check Alcotest.int "value matches" value got_value;
        Action.ok () )
  in
  Alcotest.check (testable Alcotest.unit)
    "bind passes the correct value to caller code" (Ok (), ![], []) got

let mk_test ~env ~expected name a ty =
  let got = Action.dry_run ~env a in
  Alcotest.check (testable ty) name expected got

let test_seq () =
  let test msg seq = mk_test msg (Action.seq seq) Alcotest.unit in
  let test_file b x = Alcotest.(check bool) "file exists" b x in
  test "simple sequence" ~env:![]
    ~expected:
      ( Ok (),
        ![],
        [
          "Write to path (0 bytes)";
          "Is_file? path -> true";
          "Rm path (removed)";
          "Is_file? path -> false";
        ] )
    Action.
      [
        write_file path "";
        is_file path >|= test_file true;
        rm path;
        is_file path >|= test_file false;
      ]

let test_rm () =
  let test msg ~path = mk_test msg (Action.rm path) Alcotest.unit in

  test "delete (file)" ~path
    ~env:![ (path, file); (other_path, file) ]
    ~expected:(Ok (), ![ (other_path, file) ], [ "Rm path (removed)" ]);

  let env = ![ (path, dir); (other_path, file) ] in
  test "delete (dir)" ~path ~env
    ~expected:(error "path is a directory", env, [ "Rm path (error)" ]);

  let env = ![ (other_path, file) ] in
  test "delete (file does not exist)" ~path ~env
    ~expected:(Ok (), env, [ "Rm path (no-op)" ])

let test_mkdir () =
  let test msg ~path = mk_test msg (Action.mkdir path) Alcotest.bool in

  test "mkdir (new dir)" ~path
    ~env:![ (other_path, file) ]
    ~expected:
      (Ok true, ![ (other_path, file); (path, dir) ], [ "Mkdir path (created)" ]);

  let env = ![ (other_path, file); (path, dir) ] in
  test "mdkir (existing dir)" ~path ~env
    ~expected:(Ok false, env, [ "Mkdir path (already exists)" ]);

  let env = ![ (path, file) ] in
  test "mdkir (existing file)" ~path ~env
    ~expected:
      (error "a file named 'path' already exists", env, [ "Mkdir path (error)" ])

let test_rmdir () =
  let test msg ~path = mk_test msg (Action.rmdir path) Alcotest.unit in

  let env = ![ (other_path, dir) ] in
  test "rmdir (non-existing dir)" ~path ~env
    ~expected:(Ok (), env, [ "Rmdir path (no-op)" ]);

  test "rmdir (existing dir)" ~path
    ~env:![ (path, file); (other_path, dir) ]
    ~expected:(Ok (), ![ (other_path, dir) ], [ "Rmdir path (removed)" ]);

  let env =
    ![
       (other_path, file); (Fpath.(path / "1"), dir); (Fpath.(path / "2"), file);
     ]
  in
  test "rmdir (dir with contents)" ~path ~env
    ~expected:(Ok (), ![ (other_path, file) ], [ "Rmdir path (removed)" ])

let test_with_dir () =
  let test msg ~path op = mk_test msg (Action.with_dir path op) Alcotest.unit in

  test "with_dir (create file)" ~path ~env:![]
    ~expected:
      ( Ok (),
        ![ (Fpath.(path // other_path), file) ],
        [ "With_dir path [Write to other_path (6 bytes)]" ] )
    (fun () -> Action.write_file other_path file)

let test_pwd () =
  let test msg = mk_test msg (Action.pwd ()) fpath in

  test "pwd (root)" ~env:![] ~expected:(Ok (Fpath.v "/"), ![], [ "Pwd -> /" ]);

  let env = Action.env ~pwd:(Fpath.v "/foo/bar") () in
  test "pwd (env)" ~env
    ~expected:(Ok (Fpath.v "/foo/bar"), env, [ "Pwd -> /foo/bar" ])

let test_is_file () =
  let test msg ~path = mk_test msg (Action.is_file path) Alcotest.bool in

  let env = ![ (path, file) ] in
  test "file exists (true)" ~path ~env
    ~expected:(Ok true, env, [ "Is_file? path -> true" ]);

  let env = ![ (other_path, file) ] in
  test "file exists (false)" ~path ~env
    ~expected:(Ok false, env, [ "Is_file? path -> false" ])

let test_is_dir () =
  let test msg ~path = mk_test msg (Action.is_dir path) Alcotest.bool in

  let env = ![ (path, dir) ] in
  test "dir exists (exact dir)" ~path ~env
    ~expected:(Ok true, env, [ "Is_dir? path -> true" ]);

  let env = ![ (path, file) ] in
  test "dir exists (file)" ~path ~env
    ~expected:(Ok false, env, [ "Is_dir? path -> false" ]);

  let env = ![ (other_path, file) ] in
  test "dir exists (false)" ~path ~env
    ~expected:(Ok false, env, [ "Is_dir? path -> false" ]);

  let env = ![ (Fpath.(path / "1"), file) ] in
  test "dir exists (with a file in it)" ~path ~env
    ~expected:(Ok true, env, [ "Is_dir? path -> true" ])

let test_size_of () =
  let test msg ~path =
    mk_test msg (Action.size_of path) Alcotest.(option int)
  in

  let env = ![ (path, "") ] in
  test "size_of (empty)" ~path ~env
    ~expected:(Ok (Some 0), env, [ "Size_of path -> 0" ]);

  let env = ![] in
  test "size_of (error)" ~path ~env
    ~expected:(Ok None, env, [ "Size_of path -> error" ]);

  let env = ![ (path, String.make 10_000 'a') ] in
  test "size_of (large)" ~path ~env
    ~expected:(Ok (Some 10_000), env, [ "Size_of path -> 10000" ])

let test_set_var () =
  let test msg ~key ~value =
    mk_test msg (Action.set_var key value) Alcotest.unit
  in

  let env = Action.env ~env:[ ("var", "v") ] () in
  test "set_var (unset)" ~key:"var" ~value:None ~env
    ~expected:(Ok (), ![], [ "Set_var var <unset>" ]);

  let new_v = "new_v" in
  let env = Action.env ~env:[ ("var", new_v) ] () in
  test "set_var (new)" ~key:"var" ~value:(Some new_v) ~env:![]
    ~expected:(Ok (), env, [ "Set_var var new_v" ]);

  let new_v = "new_v" in
  let env v = Action.env ~env:[ ("var", v) ] () in
  test "set_var (overwrite)" ~key:"var" ~value:(Some new_v) ~env:(env "v")
    ~expected:(Ok (), env new_v, [ "Set_var var new_v" ])

let test_get_var () =
  let test msg ~key =
    mk_test msg (Action.get_var key) Alcotest.(option string)
  in

  let v = "v" in
  let env = Action.env ~env:[ ("var", v) ] () in
  test "get_var (existing)" ~key:"var" ~env
    ~expected:(Ok (Some v), env, [ "Get_var var -> v" ]);

  let env = ![] in
  test "get_var (not set)" ~key:"var" ~env
    ~expected:(Ok None, env, [ "Get_var var -> <not set>" ])

let none _ = None

let yay _ = Some ("yay", "")

let yay_err _ = Some ("yay", "err")

let test_run_cmd () =
  let test msg ?err ?out ~env ~cmd ~expected ~expected_log () =
    let env = Action.env ~commands:env () in
    let got = Action.dry_run ~env (Action.run_cmd ?err ?out cmd) in
    Alcotest.check (testable Alcotest.unit) msg
      (expected, env, expected_log)
      got
  in
  test "run_cmd fails if the command doesn't exist" ~env:none
    ~cmd:(Bos.Cmd.v "some-command")
    ~expected:(error "'some-command' not found")
    ~expected_log:[ "Run_cmd 'some-command' (error)" ]
    ();

  let cmd = Bos.Cmd.v "some-command" in
  test "run_cmd succeeds if the command exists" ~env:yay ~cmd ~expected:(Ok ())
    ~expected_log:[ "Run_cmd 'some-command' (ok)" ]
    ();

  let err_b = Buffer.create 10 in
  let err = `Fmt (Fmt.with_buffer err_b) in
  let out_b = Buffer.create 10 in
  let out = `Fmt (Fmt.with_buffer out_b) in
  test "run_cmd succeeds if the command exists" ~env:yay_err ~cmd ~out ~err
    ~expected:(Ok ())
    ~expected_log:[ "Run_cmd 'some-command' (ok)" ]
    ();
  Alcotest.(check string) "cmd out" "yay" (Buffer.contents out_b);
  Alcotest.(check string) "cmd err" "err" (Buffer.contents err_b)

let test_run_cmd_out () =
  let test msg ?err ~env ~cmd ~expected ~expected_log () =
    let env = Action.env ~commands:env () in
    let got = Action.dry_run ~env (Action.run_cmd_out ?err cmd) in
    Alcotest.check (testable Alcotest.string) msg
      (expected, env, expected_log)
      got
  in
  test "run_cmd_out fails if the command doesn't exist" ~env:none
    ~cmd:(Bos.Cmd.v "some-command")
    ~expected:(error "'some-command' not found")
    ~expected_log:[ "Run_cmd 'some-command' (error)" ]
    ();

  let cmd = Bos.Cmd.v "some-command" in
  test "run_cmd_out succeeds if the command exists" ~env:yay ~cmd
    ~expected:(Ok "yay")
    ~expected_log:[ "Run_cmd 'some-command' (ok)" ]
    ();

  let err_b = Buffer.create 10 in
  let err = `Fmt (Fmt.with_buffer err_b) in
  test "run_cmd_out succeeds if the command exists" ~env:yay_err ~cmd ~err
    ~expected:(Ok "yay")
    ~expected_log:[ "Run_cmd 'some-command' (ok)" ]
    ();
  Alcotest.(check string) "cmd_out err" "err" (Buffer.contents err_b)

let test_write_file () =
  let test msg ~path ~contents =
    mk_test msg (Action.write_file path contents) Alcotest.unit
  in

  let contents = "contents" in
  test "write to nonexisting file" ~path ~env:![] ~contents
    ~expected:(Ok (), ![ (path, contents) ], [ "Write to path (8 bytes)" ]);

  let contents = "new contents" in
  test "write to existing file" ~path
    ~env:![ (path, contents) ]
    ~contents
    ~expected:(Ok (), ![ (path, contents) ], [ "Write to path (12 bytes)" ])

let test_tmp_file () =
  let test msg ~pat = mk_test msg (Action.tmp_file pat) fpath in
  let pat : Bos.OS.File.tmp_name_pat = "path-%s" in
  let path0 = Fpath.(v "/tmp" / Fmt.str pat "0") in
  let env = ![] in
  test "create a temp file (no conflicts)" ~env ~pat
    ~expected:(Ok path0, env, [ "Tmp_file -> /tmp/path-0" ]);

  let pat : Bos.OS.File.tmp_name_pat = "path-%s" in
  let pathn n = Fpath.(v "/tmp" / Fmt.str pat (string_of_int n)) in
  let env = ![ (pathn 0, file); (pathn 1, file); (pathn 3, file) ] in
  test "create a temp file (with conflicts)" ~env ~pat
    ~expected:(Ok (pathn 2), env, [ "Tmp_file -> /tmp/path-2" ])

let test_ls () =
  let all _ = true in
  let test msg ~path = mk_test msg (Action.ls path all) (Alcotest.list fpath) in

  let env = ![] in
  test "list a non-existig path (error)" ~env ~path
    ~expected:
      (error "path: no such file or directory", env, [ "Ls path (error)" ]);

  let root = Fpath.v "root" in
  let pathn n = Fpath.(root / string_of_int n) in
  let env = ![ (pathn 0, file); (pathn 1, file); (pathn 2, file) ] in
  test "list a directory" ~env ~path:root
    ~expected:(Ok Fpath.[ v "0"; v "1"; v "2" ], env, [ "Ls root (3 entries)" ]);

  let env = ![ (path, dir) ] in
  test "list an empty directory" ~env ~path
    ~expected:(Ok [], env, [ "Ls path (0 entry)" ]);

  let env = ![ (path, file) ] in
  test "list a file" ~env ~path
    ~expected:(Ok [ path ], env, [ "Ls path (1 entry)" ])

let test_with_output () =
  let test msg ~contents ~expected =
    let env = ![] in
    let mode = 0o755 in
    let purpose = "PURPOSE" in
    let called = ref false in
    let got =
      Action.dry_run ~env
      @@ Action.with_output ~mode ~path ~purpose (fun fmt ->
             called := true;
             Fmt.pf fmt "%s" contents)
    in
    Alcotest.check (testable Alcotest.unit) msg
      ( expected,
        ![ (path, contents) ],
        [ "Write to path (mode: 0755, purpose: PURPOSE)" ] )
      got;
    Alcotest.check Alcotest.bool "k was called" true called.contents
  in
  let contents = "contents" in
  test "write" ~contents ~expected:(Ok ())

let suite =
  List.map
    (fun (n, f) -> (n, `Quick, f))
    [
      ("bind", test_bind);
      ("seq", test_seq);
      ("rm", test_rm);
      ("mkdir", test_mkdir);
      ("rmdir", test_rmdir);
      ("with_dir", test_with_dir);
      ("pwd", test_pwd);
      ("is_file", test_is_file);
      ("is_dir", test_is_dir);
      ("size_of", test_size_of);
      ("set_var", test_set_var);
      ("get_var", test_get_var);
      ("run_cmd", test_run_cmd);
      ("run_cmd_out", test_run_cmd_out);
      ("write_file", test_write_file);
      ("tmp_file", test_tmp_file);
      ("ls", test_ls);
      ("with_output", test_with_output);
    ]
