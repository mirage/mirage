open Functoria

let result_t pp_a =
  let pp ppf = function
    | `Error `Exn -> Fmt.string ppf "error exn"
    | `Error `Parse -> Fmt.string ppf "error parse"
    | `Error `Term -> Fmt.string ppf "error term"
    | `Help -> Fmt.string ppf "help"
    | `Version -> Fmt.string ppf "version"
    | `Ok action ->
        let pp = Cli.pp_action pp_a in
        Fmt.pf ppf "ok %a" pp action
  in
  Alcotest.testable pp ( = )

let result_b = result_t Fmt.(Dump.pair bool bool)

let result_u = result_t (fun ppf () -> Fmt.string ppf "()")

let eval = Cli.eval ~with_setup:false ~name:"name" ~version:"0.2"

let peek = Cli.peek ~with_setup:false

let test_configure () =
  let extra_term =
    Cmdliner.(
      Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info [ "x"; "xyz" ])))
        $ Arg.(value (flag (info [ "c"; "cde" ])))))
  in
  let result =
    eval ~configure:extra_term ~query:extra_term ~describe:extra_term
      ~build:extra_term ~clean:extra_term ~help:extra_term
      [| "name"; "configure"; "--xyz"; "--verbose" |]
  in
  Alcotest.(check result_b)
    "configure"
    (`Ok
      (Cli.Configure
         {
           context = (true, false);
           output = None;
           config_file = Fpath.v "config.ml";
           build_dir = None;
           dry_run = false;
         }))
    result

let test_describe () =
  let extra_term =
    Cmdliner.(
      Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info [ "x"; "xyz" ])))
        $ Arg.(value (flag (info [ "c"; "cde" ])))))
  in
  let result =
    eval ~configure:extra_term ~query:extra_term ~describe:extra_term
      ~build:extra_term ~clean:extra_term ~help:extra_term
      [|
        "name";
        "describe";
        "--cde";
        "--color=always";
        "--dot-command=dot";
        "--eval";
      |]
  in
  Alcotest.(check result_b)
    "describe"
    (`Ok
      (Cli.Describe
         {
           args =
             {
               context = (false, true);
               output = None;
               config_file = Fpath.v "config.ml";
               build_dir = None;
               dry_run = false;
             };
           dotcmd = "dot";
           dot = false;
           eval = Some true;
         }))
    result

let test_build () =
  let extra_term =
    Cmdliner.(
      Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info [ "x"; "xyz" ])))
        $ Arg.(value (flag (info [ "c"; "cde" ])))))
  in
  let result =
    eval ~configure:extra_term ~query:extra_term ~describe:extra_term
      ~build:extra_term ~clean:extra_term ~help:extra_term
      [| "name"; "build"; "--cde"; "-x"; "--color=never"; "-v"; "-v" |]
  in
  Alcotest.(check result_b)
    "build"
    (`Ok
      (Cli.Build
         {
           context = (true, true);
           output = None;
           config_file = Fpath.v "config.ml";
           build_dir = None;
           dry_run = false;
         }))
    result

let test_clean () =
  let extra_term =
    Cmdliner.(
      Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info [ "x"; "xyz" ])))
        $ Arg.(value (flag (info [ "c"; "cde" ])))))
  in
  let result =
    eval ~configure:extra_term ~query:extra_term ~describe:extra_term
      ~build:extra_term ~clean:extra_term ~help:extra_term [| "name"; "clean" |]
  in
  Alcotest.(check result_b)
    "clean"
    (`Ok
      (Cli.Clean
         {
           context = (false, false);
           output = None;
           config_file = Fpath.v "config.ml";
           build_dir = None;
           dry_run = false;
         }))
    result

let test_help () =
  let extra_term =
    Cmdliner.(
      Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info [ "x"; "xyz" ])))
        $ Arg.(value (flag (info [ "c"; "cde" ])))))
  in
  let null = Fmt.with_buffer (Buffer.create 10) in
  let result =
    eval ~help_ppf:null ~configure:extra_term ~query:extra_term
      ~describe:extra_term ~build:extra_term ~clean:extra_term ~help:extra_term
      [| "name"; "help"; "--help"; "plain" |]
  in
  Alcotest.(check result_b) "help" `Help result

let test_default () =
  let extra_term =
    Cmdliner.(
      Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info [ "x"; "xyz" ])))
        $ Arg.(value (flag (info [ "c"; "cde" ])))))
  in
  let null = Fmt.with_buffer (Buffer.create 10) in
  let result =
    eval ~help_ppf:null ~configure:extra_term ~query:extra_term
      ~describe:extra_term ~build:extra_term ~clean:extra_term ~help:extra_term
      [| "name" |]
  in
  Alcotest.(check result_b) "default" `Help result

let test_peek () =
  let result = peek [| ""; "config"; "-x"; "--foo"; "-obar" |] in
  Alcotest.(check result_u)
    "peek config"
    (`Ok
      (Cli.Configure
         {
           context = ();
           output = Some "bar";
           build_dir = None;
           config_file = Fpath.v "config.ml";
           dry_run = false;
         }))
    result;

  let result = peek [| ""; "c"; "-x"; "--foo"; "-obar" |] in
  Alcotest.(check result_u) "peek ambiguous" (`Error `Parse) result;

  let result =
    peek [| ""; "build"; "-x"; "--foo"; "--dry-run"; "-y"; "-a"; "--file=bar" |]
  in
  Alcotest.(check result_u)
    "peek build"
    (`Ok
      (Cli.Build
         {
           context = ();
           output = None;
           build_dir = None;
           config_file = Fpath.v "bar";
           dry_run = true;
         }))
    result

let test_read_full_eval () =
  let check = Alcotest.(check @@ option bool) in
  check "test" None (Cli.peek_full_eval [| "test" |]);

  check "test --eval" (Some true) (Cli.peek_full_eval [| "test"; "--eval" |]);

  check "test blah --eval blah" (Some true)
    (Cli.peek_full_eval [| "test"; "blah"; "--eval"; "blah" |]);

  check "test --no-eval" (Some false)
    (Cli.peek_full_eval [| "test"; "--no-eval" |]);

  check "test blah --no-eval blah" (Some false)
    (Cli.peek_full_eval [| "test"; "blah"; "--no-eval"; "blah" |]);

  check "--no-eval test --eval" (Some true)
    (Cli.peek_full_eval [| "--no-eval"; "test"; "--eval" |]);

  check "--eval test --no-eval" (Some false)
    (Cli.peek_full_eval [| "--eval"; "test"; "--no-eval" |])

let test_generated_header () =
  let expected = "Generated by \"prog arg1 arg2\"." in
  let got = Codegen.generated_header ~argv:[| "prog"; "arg1"; "arg2" |] () in
  Alcotest.check Alcotest.string "generated_header" expected got

let suite =
  [
    ("read_full_eval", `Quick, test_read_full_eval);
    ("configure", `Quick, test_configure);
    ("describe", `Quick, test_describe);
    ("build", `Quick, test_build);
    ("clean", `Quick, test_clean);
    ("help", `Quick, test_help);
    ("default", `Quick, test_default);
    ("peek", `Quick, test_peek);
    ("generated_header", `Quick, test_generated_header);
  ]
