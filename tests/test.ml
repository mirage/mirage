(*
 * Copyright (c) 2015 Jeremy Yallop
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Astring
module Cmd = Functoria_command_line

module Parsing = struct

  let result_t =
    let pp ppf = function
      | `Error `Exn   -> Fmt.string ppf "error exn"
      | `Error `Parse -> Fmt.string ppf "error parse"
      | `Error `Term  -> Fmt.string ppf "error term"
      | `Help         -> Fmt.string ppf "help"
      | `Version      -> Fmt.string ppf "version"
      | `Ok action    ->
        let pp = Cmd.pp_action Fmt.(Dump.pair bool bool) in
        Fmt.pf ppf "ok %a" pp action
    in
    Alcotest.testable pp (=)

  let test_configure () =
    let extra_term = Cmdliner.(Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info ["x"; "xyz"])))
        $ Arg.(value (flag (info ["c"; "cde"])))
      ))
    in
    let result =
      Cmd.parse_args ~name:"name" ~version:"0.2"
        ~configure:extra_term
        ~describe:extra_term
        ~build:extra_term
        ~clean:extra_term
        ~help:extra_term
        [|"name"; "configure"; "--xyz"; "--verbose"|]
    in
    Alcotest.(check result_t) "configure"
      (`Ok (Cmd.Configure { result = (true, false); output = None }))
      result


  let test_describe () =
    let extra_term = Cmdliner.(Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info ["x"; "xyz"])))
        $ Arg.(value (flag (info ["c"; "cde"])))
      ))
    in
    let result =
      Cmd.parse_args ~name:"name" ~version:"0.2"
        ~configure:extra_term
        ~describe:extra_term
        ~build:extra_term
        ~clean:extra_term
        ~help:extra_term
        [|"name"; "describe"; "--cde";
          "--color=always"; "--dot-command=dot"; "--eval"|]
    in
    Alcotest.(check result_t) "describe"
      (`Ok (Cmd.Describe { result = (false, true);
                           dotcmd = "dot";
                           dot = false;
                           output = None }))
      result

  let test_build () =
    let extra_term = Cmdliner.(Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info ["x"; "xyz"])))
        $ Arg.(value (flag (info ["c"; "cde"])))
      ))
    in
    let result =
      Cmd.parse_args ~name:"name" ~version:"0.2"
        ~configure:extra_term
        ~describe:extra_term
        ~build:extra_term
        ~clean:extra_term
        ~help:extra_term
        [|"name"; "build"; "--cde"; "-x"; "--color=never"; "-v"; "-v"|]
    in
    Alcotest.(check result_t) "build"
      (`Ok (Cmd.Build (true, true)))
      result

  let test_clean () =
    let extra_term = Cmdliner.(Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info ["x"; "xyz"])))
        $ Arg.(value (flag (info ["c"; "cde"])))
      ))
    in
    let result =
      Cmd.parse_args ~name:"name" ~version:"0.2"
        ~configure:extra_term
        ~describe:extra_term
        ~build:extra_term
        ~clean:extra_term
        ~help:extra_term
        [|"name"; "clean"|]
    in
    Alcotest.(check result_t) "clean"
      (`Ok (Cmd.Clean (false, false)))
      result


  let test_help () =
    let extra_term = Cmdliner.(Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info ["x"; "xyz"])))
        $ Arg.(value (flag (info ["c"; "cde"])))
      ))
    in
    let result =
      Cmd.parse_args ~name:"name" ~version:"0.2"
        ~configure:extra_term
        ~describe:extra_term
        ~build:extra_term
        ~clean:extra_term
        ~help:extra_term
        [|"name"; "help"; "--help"; "plain"|]
    in
    Alcotest.(check result_t) "help" `Help result

  let test_default () =
    let extra_term = Cmdliner.(Term.(
        pure (fun xyz cde -> (xyz, cde))
        $ Arg.(value (flag (info ["x"; "xyz"])))
        $ Arg.(value (flag (info ["c"; "cde"])))
      ))
    in
    let result =
      Cmd.parse_args ~name:"name" ~version:"0.2"
        ~configure:extra_term
        ~describe:extra_term
        ~build:extra_term
        ~clean:extra_term
        ~help:extra_term
        [|"name"|]
    in
    Alcotest.(check result_t) "default" `Help result

  let test_read_full_eval () =
    let check = Alcotest.(check @@ option bool) in
    begin
      check "test" None
        (Cmd.read_full_eval [|"test"|]);

      check "test --eval" (Some true)
        (Cmd.read_full_eval [|"test"; "--eval"|]);

      check "test blah --eval blah" (Some true)
        (Cmd.read_full_eval [|"test"; "blah"; "--eval"; "blah"|]);

      check "test --no-eval" (Some false)
        (Cmd.read_full_eval [|"test"; "--no-eval"|]);

      check "test blah --no-eval blah" (Some false)
        (Cmd.read_full_eval [|"test"; "blah"; "--no-eval"; "blah"|]);

      check "--no-eval test --eval" (Some true)
        (Cmd.read_full_eval [|"--no-eval"; "test"; "--eval"|]);

      check "--eval test --no-eval" (Some false)
        (Cmd.read_full_eval [|"--eval"; "test"; "--no-eval"|]);
    end

  let suite = [
    "read_full_eval", `Quick, test_read_full_eval;
    "configure"     , `Quick, test_configure;
    "describe"      , `Quick, test_describe;
    "build"         , `Quick, test_build;
    "clean"         , `Quick, test_clean;
    "help"          , `Quick, test_help;
    "default"       , `Quick, test_default;
  ]

end

module Full = struct

  let list_files dir =
    let dir = Fpath.v dir in
    let l = Bos.OS.Path.matches ~dotfiles:true Fpath.(dir / "$(file)") in
    match l with
    | Error (`Msg e) -> Fmt.kstrf Alcotest.fail "list_files: %s" e
    | Ok l ->
      List.sort String.compare @@
      List.rev_map (fun x ->
          match Fpath.relativize ~root:dir x with
          | None   -> assert false
          | Some d -> Fpath.to_string d
        ) l

  let get_ok = function
    | Ok x           -> x
    | Error (`Msg e) -> Alcotest.fail e

  let clean_app () =
    get_ok @@ Bos.OS.Dir.delete ~recurse:true Fpath.(v "app/_build");
    get_ok @@ Bos.OS.File.delete Fpath.(v "app/main.ml");
    get_ok @@ Bos.OS.File.delete Fpath.(v "app/.mirage.config");
    get_ok @@ Bos.OS.File.delete Fpath.(v "app/jbuild");
    get_ok @@ Bos.OS.File.delete Fpath.(v "app/.merlin")

  (* cut a man page into sections *)
  let by_sections s =
    let lines = String.cuts ~sep:"\n" s in
    let return l = match List.rev l with
      | []   -> assert false
      | h::t -> h, t
    in
    let rec aux current sections = function
      | []     -> List.rev (return current :: sections)
      | h :: t ->
        if String.length h > 1
        && String.for_all (fun x -> Char.Ascii.(is_upper x || is_white x)) h
        then
          aux [h] (return current :: sections) t
        else
          aux (h :: current) sections t
    in
    aux ["INIT"] [] lines

  let files = Alcotest.(slist string String.compare)

  let test_configure () =
    clean_app ();
    (* check that configure generates the file in the right dir when
       --file is passed. *)
    Alcotest.(check files) "the usual files should be present before configure"
      ["app.ml"; "config.ml"; "myocamlbuild.ml"] (list_files "app");
    Test_app.run_with_argv
      [| ""; "configure"; "-vv";
         "--file"; "app/config.ml" |];
    Alcotest.(check files) "new files should be created in the source dir"
      ["app.ml"; "config.ml"; "myocamlbuild.ml";
       "main.ml"; ".mirage.config"; "jbuild"; "_build"
      ] (list_files "app");

    clean_app ();
    (* check that configure generates the file in the right dir when
       --root is passed. *)
    let files = Alcotest.(slist string String.compare) in
    Alcotest.(check files) "the usual files should be present before configure"
      ["app.ml"; "config.ml"; "myocamlbuild.ml"] (list_files "app");
    Test_app.run_with_argv
      [| ""; "configure"; "-vv";
         "--file"; "app/config.ml"; "--root"; "_root" |];
    Alcotest.(check files) "only _build should be created in the source dir"
      ["app.ml"; "config.ml"; "myocamlbuild.ml"; "_build"]
      (list_files "app");
    Alcotest.(check files) "other files should be created in _root"
      ["main.ml"; ".mirage.config"; "jbuild"]
      (list_files "_root");

    (* check that configure is writting the correct .mirage.config file *)
    let test_config root cfg =
      Test_app.run_with_argv (Array.of_list cfg);
      let config =
        get_ok @@ Bos.OS.File.read Fpath.(v root / ".mirage.config")
        |> String.trim
      in
      Alcotest.(check string) ("config should persist in " ^ root)
        (String.concat ~sep:";" cfg) config
    in

    test_config "_root"
      [""; "configure"; "-vv"; "--file=app/config.ml"; "--root=_root"];
    test_config "app"
      [""; "configure"; "-vv"; "--file=app/config.ml"];

    (* check that `test help configure` and `test configure --help` have
       the same output. *)
    let b1 = Buffer.create 128 and b2 = Buffer.create 128 in
    Test_app.run_with_argv ~help_ppf:(Format.formatter_of_buffer b1)
      [| ""; "help"; "configure"; "--file=app/config.ml"; "--help=plain" |];
    Test_app.run_with_argv ~help_ppf:(Format.formatter_of_buffer b2)
      [| ""; "configure"; "--file=app/config.ml"; "--help=plain" |];
    let s1 = Buffer.contents b1 and s2 = Buffer.contents b2 in

    let s1 = by_sections s1 and s2 = by_sections s2 in
    Alcotest.(check (list string))
      "help messages have the same configure options"
      (List.assoc "CONFIGURE OPTIONS" s1)
      (List.assoc "CONFIGURE OPTIONS" s2);
    Alcotest.(check (list string))
      "help messages have the same unikernel parameters"
      (List.assoc "UNIKERNEL OPTIONS" s1)
      (List.assoc "UNIKERNEL OPTIONS" s2);
    Alcotest.(check (list string))
      "help messages have the same common options"
      (List.assoc "COMMON OPTIONS" s1)
      (List.assoc "COMMON OPTIONS" s2);

    (* check that `test help configure` works when no config.ml file
       is present. *)
    let b3 = Buffer.create 128 in
    let b4 = Buffer.create 128 in
    Test_app.run_with_argv
      ~err_ppf:(Format.formatter_of_buffer b3)
      ~help_ppf:(Format.formatter_of_buffer b4)
      [| ""; "help"; "configure"; "--help=plain" |];
    let s3 = Buffer.contents b3 in
    let s4 = by_sections (Buffer.contents b4) in
    Alcotest.(check string) "no errors" s3 "";
    Alcotest.(check bool) "name should be present"
      true (List.mem_assoc "NAME" s4);
    Alcotest.(check bool) "synopsis should be present"
      true (List.mem_assoc "SYNOPSIS" s4)

  let test_describe () =
    Test_app.run_with_argv
      [| ""; "describe"; "-vv";
         "--file"; "app/config.ml"|]

  let test_build () =
    clean_app ();
    (* default build *)
    Test_app.run_with_argv [| ""; "configure"; "--file"; "app/config.ml"|];
    Test_app.run_with_argv [| ""; "build"; "-vv"; "--file"; "app/config.ml"|];
    Alcotest.(check bool) "main.exe should be built" true
      (Sys.file_exists "app/_build/default/main.exe");

    (* test --output *)
    Test_app.run_with_argv
      [| ""; "configure"; "--file"; "app/config.ml"; "-o"; "toto"|];
    Test_app.run_with_argv
      [| ""; "build"; "-vv"; "--file"; "app/config.ml"|];
    Alcotest.(check bool) "toto.exe should be built" true
      (Sys.file_exists "app/_build/default/toto.exe")

  let test_clean () =
    Test_app.run_with_argv
      [| ""; "clean"; "-vv";
         "--file"; "app/config.ml"|]

  let test_help () =
    Test_app.run_with_argv
      [| ""; "help"; "-vv"; "--help=plain" |]

  let test_default () =
    Test_app.run_with_argv
      [| ""; "-vv"; |]

  let suite = [
    "configure"     , `Quick, test_configure;
    "describe"      , `Quick, test_describe;
    "build"         , `Quick, test_build;
    "clean"         , `Quick, test_clean;
    "help"          , `Quick, test_help;
    "default"       , `Quick, test_default;
  ]

end

let suite  = [
  "parsing", Parsing.suite;
  "full"   , Full.suite;
]

let () = Alcotest.run "functoria" suite
