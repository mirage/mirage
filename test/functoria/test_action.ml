open Functoria
open Action.Syntax

let pp_unit ppf () = Fmt.string ppf "()"
let domain pp = Alcotest.testable (Action.pp_domain pp) (Action.eq_domain ( = ))
let file = "<file>"
let dir = "<DIR>"
let error e = Error (`Msg e)
let ( ! ) files = Action.env ~files:(`Files files) ()
let path = Fpath.v "path"
let other_path = Fpath.v "other_path"
let dom result env logs = { Action.result; env; logs }

let test_bind () =
  let got =
    Action.dry_run
      ~env:![ (path, file); (other_path, file) ]
      (let* () = Action.rm path in
       Action.rm other_path)
  in
  Alcotest.check (domain pp_unit) "sequence"
    (dom (Ok ()) ![] [ "Rm path (removed)"; "Rm other_path (removed)" ])
    got;

  let got =
    Action.dry_run
      ~env:![ (other_path, dir) ]
      (let* () = Action.rm path in
       Action.rm other_path)
  in
  Alcotest.check (domain pp_unit) "sequence after error"
    (dom
       (error "other_path is a directory")
       ![ (other_path, dir) ]
       [ "Rm path (no-op)"; "Rm other_path (error)" ])
    got;

  let got =
    let value = 5 in
    Action.dry_run ~env:![]
      (let* got_value = Action.ok value in
       Alcotest.check Alcotest.int "value matches" value got_value;
       Action.ok ())
  in
  Alcotest.check (domain pp_unit) "bind passes the correct value to caller code"
    (dom (Ok ()) ![] []) got

let mk_test ~env ~expected name a ty =
  let got = Action.dry_run ~env a in
  Alcotest.check (domain ty) name expected got

let test_seq () =
  let test msg seq = mk_test msg (Action.seq seq) pp_unit in
  let test_file b x = Alcotest.(check bool) "file exists" b x in
  test "simple sequence" ~env:![]
    ~expected:
      (dom (Ok ()) ![]
         [
           "Write to path (0 bytes)";
           "Is_file? path -> true";
           "Rm path (removed)";
           "Is_file? path -> false";
         ])
    Action.
      [
        write_file path "";
        (let+ is_file = is_file path in
         test_file true is_file);
        rm path;
        (let+ is_file = is_file path in
         test_file false is_file);
      ]

let test_rm () =
  let test msg ~path = mk_test msg (Action.rm path) pp_unit in

  test "delete (file)" ~path
    ~env:![ (path, file); (other_path, file) ]
    ~expected:(dom (Ok ()) ![ (other_path, file) ] [ "Rm path (removed)" ]);

  let env = ![ (path, dir); (other_path, file) ] in
  test "delete (dir)" ~path ~env
    ~expected:(dom (error "path is a directory") env [ "Rm path (error)" ]);

  let env = ![ (other_path, file) ] in
  test "delete (file does not exist)" ~path ~env
    ~expected:(dom (Ok ()) env [ "Rm path (no-op)" ])

let test_mkdir () =
  let test msg ~path = mk_test msg (Action.mkdir path) Fmt.bool in

  test "mkdir (new dir)" ~path
    ~env:![ (other_path, file) ]
    ~expected:
      (dom (Ok true)
         ![ (other_path, file); (path, dir) ]
         [ "Mkdir path (created)" ]);

  let env = ![ (other_path, file); (path, dir) ] in
  test "mdkir (existing dir)" ~path ~env
    ~expected:(dom (Ok false) env [ "Mkdir path (already exists)" ]);

  let env = ![ (path, file) ] in
  test "mdkir (existing file)" ~path ~env
    ~expected:
      (dom
         (error "a file named 'path' already exists")
         env [ "Mkdir path (error)" ])

let test_rmdir () =
  let test msg ~path = mk_test msg (Action.rmdir path) pp_unit in

  let env = ![ (other_path, dir) ] in
  test "rmdir (non-existing dir)" ~path ~env
    ~expected:(dom (Ok ()) env [ "Rmdir path (no-op)" ]);

  test "rmdir (existing dir)" ~path
    ~env:![ (path, file); (other_path, dir) ]
    ~expected:(dom (Ok ()) ![ (other_path, dir) ] [ "Rmdir path (removed)" ]);

  let env =
    ![
       (other_path, file); (Fpath.(path / "1"), dir); (Fpath.(path / "2"), file);
     ]
  in
  test "rmdir (dir with contents)" ~path ~env
    ~expected:(dom (Ok ()) ![ (other_path, file) ] [ "Rmdir path (removed)" ])

let test_with_dir () =
  let test msg ~path op = mk_test msg (Action.with_dir path op) pp_unit in

  test "with_dir (create file)" ~path ~env:![]
    ~expected:
      (dom (Ok ())
         ![ (Fpath.(path // other_path), file) ]
         [ "With_dir path [Write to other_path (6 bytes)]" ])
    (fun () -> Action.write_file other_path file)

let test_pwd () =
  let test msg = mk_test msg (Action.pwd ()) Fpath.pp in

  test "pwd (root)" ~env:![]
    ~expected:(dom (Ok (Fpath.v "/")) ![] [ "Pwd -> /" ]);

  let env = Action.env ~pwd:(Fpath.v "/foo/bar") () in
  test "pwd (env)" ~env
    ~expected:(dom (Ok (Fpath.v "/foo/bar")) env [ "Pwd -> /foo/bar" ])

let test_is_file () =
  let test msg ~path = mk_test msg (Action.is_file path) Fmt.bool in

  let env = ![ (path, file) ] in
  test "file exists (true)" ~path ~env
    ~expected:(dom (Ok true) env [ "Is_file? path -> true" ]);

  let env = ![ (other_path, file) ] in
  test "file exists (false)" ~path ~env
    ~expected:(dom (Ok false) env [ "Is_file? path -> false" ])

let test_is_dir () =
  let test msg ~path = mk_test msg (Action.is_dir path) Fmt.bool in

  let env = ![ (path, dir) ] in
  test "dir exists (exact dir)" ~path ~env
    ~expected:(dom (Ok true) env [ "Is_dir? path -> true" ]);

  let env = ![ (path, file) ] in
  test "dir exists (file)" ~path ~env
    ~expected:(dom (Ok false) env [ "Is_dir? path -> false" ]);

  let env = ![ (other_path, file) ] in
  test "dir exists (false)" ~path ~env
    ~expected:(dom (Ok false) env [ "Is_dir? path -> false" ]);

  let env = ![ (Fpath.(path / "1"), file) ] in
  test "dir exists (with a file in it)" ~path ~env
    ~expected:(dom (Ok true) env [ "Is_dir? path -> true" ])

let test_size_of () =
  let test msg ~path =
    mk_test msg (Action.size_of path) Fmt.(Dump.option int)
  in

  let env = ![ (path, "") ] in
  test "size_of (empty)" ~path ~env
    ~expected:(dom (Ok (Some 0)) env [ "Size_of path -> 0" ]);

  let env = ![] in
  test "size_of (error)" ~path ~env
    ~expected:(dom (Ok None) env [ "Size_of path -> error" ]);

  let env = ![ (path, String.make 10_000 'a') ] in
  test "size_of (large)" ~path ~env
    ~expected:(dom (Ok (Some 10_000)) env [ "Size_of path -> 10000" ])

let test_set_var () =
  let test msg ~key ~value = mk_test msg (Action.set_var key value) pp_unit in

  let env = Action.env ~env:[ ("var", "v") ] () in
  test "set_var (unset)" ~key:"var" ~value:None ~env
    ~expected:(dom (Ok ()) ![] [ "Set_var var <unset>" ]);

  let new_v = "new_v" in
  let env = Action.env ~env:[ ("var", new_v) ] () in
  test "set_var (new)" ~key:"var" ~value:(Some new_v) ~env:![]
    ~expected:(dom (Ok ()) env [ "Set_var var new_v" ]);

  let new_v = "new_v" in
  let env v = Action.env ~env:[ ("var", v) ] () in
  test "set_var (overwrite)" ~key:"var" ~value:(Some new_v) ~env:(env "v")
    ~expected:(dom (Ok ()) (env new_v) [ "Set_var var new_v" ])

let test_get_var () =
  let test msg ~key =
    mk_test msg (Action.get_var key) Fmt.(Dump.option string)
  in

  let v = "v" in
  let env = Action.env ~env:[ ("var", v) ] () in
  test "get_var (existing)" ~key:"var" ~env
    ~expected:(dom (Ok (Some v)) env [ "Get_var var -> v" ]);

  let env = ![] in
  test "get_var (not set)" ~key:"var" ~env
    ~expected:(dom (Ok None) env [ "Get_var var -> <not set>" ])

let none _ = None
let yay _ = Some ("yay", "")
let yay_err _ = Some ("yay", "err")

let test_run_cmd () =
  let test msg ?err ?out ~exec ~cmd ~expected ~expected_log () =
    let env = Action.env ~exec () in
    let got = Action.dry_run ~env (Action.run_cmd ?err ?out cmd) in
    Alcotest.check (domain pp_unit) msg (dom expected env expected_log) got
  in
  test "run_cmd fails if the command doesn't exist" ~exec:none
    ~cmd:(Bos.Cmd.v "some-command")
    ~expected:(error "'some-command' not found")
    ~expected_log:[ "Run_cmd 'some-command' (error)" ]
    ();

  let cmd = Bos.Cmd.v "some-command" in
  test "run_cmd succeeds if the command exists" ~exec:yay ~cmd ~expected:(Ok ())
    ~expected_log:[ "Run_cmd 'some-command' (ok)" ]
    ();

  let err_b = Buffer.create 10 in
  let err = `Fmt (Fmt.with_buffer err_b) in
  let out_b = Buffer.create 10 in
  let out = `Fmt (Fmt.with_buffer out_b) in
  test "run_cmd succeeds if the command exists" ~exec:yay_err ~cmd ~out ~err
    ~expected:(Ok ())
    ~expected_log:[ "Run_cmd 'some-command' (ok)" ]
    ();
  Alcotest.(check string) "cmd out" "yay" (Buffer.contents out_b);
  Alcotest.(check string) "cmd err" "err" (Buffer.contents err_b)

let test_run_cmd_out () =
  let test msg ?err ~exec ~cmd ~expected ~expected_log () =
    let env = Action.env ~exec () in
    let got = Action.dry_run ~env (Action.run_cmd_out ?err cmd) in
    Alcotest.check (domain Fmt.string) msg (dom expected env expected_log) got
  in
  test "run_cmd_out fails if the command doesn't exist" ~exec:none
    ~cmd:(Bos.Cmd.v "some-command")
    ~expected:(error "'some-command' not found")
    ~expected_log:[ "Run_cmd 'some-command' (error)" ]
    ();

  let cmd = Bos.Cmd.v "some-command" in
  test "run_cmd_out succeeds if the command exists" ~exec:yay ~cmd
    ~expected:(Ok "yay")
    ~expected_log:[ "Run_cmd 'some-command' (ok)" ]
    ();

  let err_b = Buffer.create 10 in
  let err = `Fmt (Fmt.with_buffer err_b) in
  test "run_cmd_out succeeds if the command exists" ~exec:yay_err ~cmd ~err
    ~expected:(Ok "yay")
    ~expected_log:[ "Run_cmd 'some-command' (ok)" ]
    ();
  Alcotest.(check string) "cmd_out err" "err" (Buffer.contents err_b)

let test_write_file () =
  let test msg ~path ~contents =
    mk_test msg (Action.write_file path contents) pp_unit
  in

  let contents = "contents" in
  test "write to nonexisting file" ~path ~env:![] ~contents
    ~expected:(dom (Ok ()) ![ (path, contents) ] [ "Write to path (8 bytes)" ]);

  let contents = "new contents" in
  test "write to existing file" ~path
    ~env:![ (path, contents) ]
    ~contents
    ~expected:(dom (Ok ()) ![ (path, contents) ] [ "Write to path (12 bytes)" ])

let test_tmp_file () =
  let test msg ~pat = mk_test msg (Action.tmp_file pat) Fpath.pp in
  let pat : Bos.OS.File.tmp_name_pat = "path-%s" in
  let path0 = Fpath.(v "/tmp" / Fmt.str pat "0") in
  let env = ![] in
  test "create a temp file (no conflicts)" ~env ~pat
    ~expected:(dom (Ok path0) env [ "Tmp_file -> /tmp/path-0" ]);

  let pat : Bos.OS.File.tmp_name_pat = "path-%s" in
  let pathn n = Fpath.(v "/tmp" / Fmt.str pat (string_of_int n)) in
  let env = ![ (pathn 0, file); (pathn 1, file); (pathn 3, file) ] in
  test "create a temp file (with conflicts)" ~env ~pat
    ~expected:(dom (Ok (pathn 2)) env [ "Tmp_file -> /tmp/path-2" ])

let test_ls () =
  let all _ = true in
  let test msg ~path =
    mk_test msg (Action.ls path all) (Fmt.Dump.list Fpath.pp)
  in

  let env = ![] in
  test "list a non-existig path (error)" ~env ~path
    ~expected:
      (dom (error "path: no such file or directory") env [ "Ls path (error)" ]);

  let root = Fpath.v "root" in
  let pathn n = Fpath.(root / string_of_int n) in
  let env = ![ (pathn 0, file); (pathn 1, file); (pathn 2, file) ] in
  test "list a directory" ~env ~path:root
    ~expected:
      (dom (Ok Fpath.[ v "0"; v "1"; v "2" ]) env [ "Ls root (3 entries)" ]);

  let env = ![ (path, dir) ] in
  test "list an empty directory" ~env ~path
    ~expected:(dom (Ok []) env [ "Ls path (0 entry)" ]);

  let env = ![ (path, file) ] in
  test "list a file" ~env ~path
    ~expected:(dom (Ok [ path ]) env [ "Ls path (1 entry)" ])

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
    Alcotest.check (domain pp_unit) msg
      (dom expected
         ![ (path, contents) ]
         [ "Write to path (mode: 0755, purpose: PURPOSE)" ])
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
