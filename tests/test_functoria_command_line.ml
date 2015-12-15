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

open OUnit2

open Functoria_misc
module Cmd = Functoria_command_line


let test_configure _ =
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
      [|"name"; "configure"; "--xyz"; "--verbose"; "--no-opam"|]
  in
  assert_equal
    (`Ok (Cmd.Configure { result = (true, false);
                          no_opam = true;
                          no_opam_version = false;
                          no_depext = false }))
    result


let test_describe _ =
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
      [|"name"; "describe"; "--cde"; "--file=config.ml";
        "--color=always"; "--dot-command=dot"; "--eval"|]
  in
  assert_equal
    (`Ok (Cmd.Describe { result = (false, true);
                         dotcmd = "dot";
                         dot = false;
                         output = None }))
    result


let test_build _ =
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
  assert_equal
    (`Ok (Cmd.Build (true, true)))
    result


let test_clean _ =
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
  assert_equal
    (`Ok (Cmd.Clean (false, false)))
    result


let test_help _ =
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
      [|"name"; "help"; "--verbose"|]
  in
  assert_equal `Help result


let test_default _ =
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
  assert_equal `Help result


let test_read_log_level _ =
  begin
    assert_equal Log.WARN
      (Cmd.read_log_level [|"test"|]);

    assert_equal Log.INFO
      (Cmd.read_log_level [|"test"; "blah"; "-verbose"; "blah"|]);

    assert_equal Log.INFO
      (Cmd.read_log_level [|"test"; "-verbose"|]);

    assert_equal Log.DEBUG
      (Cmd.read_log_level [|"test"; "blah"; "-verbose"; "blah"; "-verbose"|]);
  end


let test_read_colour_option _ =
  begin
    assert_equal None
      (Cmd.read_colour_option [|"test"|]);

    assert_equal None
      (Cmd.read_colour_option [|"test"; "--color=auto"|]);

    assert_equal None
      (Cmd.read_colour_option [|"test"; "blah"; "--color=auto"|]);

    assert_equal (Some `Ansi_tty)
      (Cmd.read_colour_option [|"test"; "--color=always"|]);

    assert_equal (Some `Ansi_tty)
      (Cmd.read_colour_option [|"test"; "blah"; "--color=always"|]);

    assert_equal (Some `None)
      (Cmd.read_colour_option [|"test"; "blah"; "--color=never"|]);
  end


let test_read_config_file _ =
  begin
    assert_equal None
      (Cmd.read_config_file [|"test"|]);

    assert_equal (Some "config.ml")
      (Cmd.read_config_file [|"test"; "blah"; "-f"; "config.ml"|]);

    assert_equal (Some "config.ml")
      (Cmd.read_config_file [|"test"; "blah"; "--file=config.ml"|]);

    assert_equal (Some "config.ml")
      (Cmd.read_config_file [|"test"; "-f"; "config.ml"; "blah"|]);

    assert_equal (Some "config.ml")
      (Cmd.read_config_file [|"test"; "--file=config.ml"|]);
  end


let test_read_full_eval _ =
  begin
    assert_equal false
      (Cmd.read_full_eval [|"test"|]);

    assert_equal true
      (Cmd.read_full_eval [|"test"; "--eval"|]);

    assert_equal true
      (Cmd.read_full_eval [|"test"; "blah"; "--eval"; "blah"|]);
  end


let suite = "Command-line parsing tests" >:::
  ["read_log_level"
    >:: test_read_log_level;

   "read_colour_option"
    >:: test_read_colour_option;

   "read_config_file"
    >:: test_read_config_file;

   "read_full_eval"
    >:: test_read_full_eval;

    "configure"
    >:: test_configure;

    "describe"
    >:: test_describe;

    "build"
    >:: test_build;

    "clean"
    >:: test_clean;

    "help"
    >:: test_help;

    "default"
    >:: test_default;
  ]


let _ =
  run_test_tt_main suite
