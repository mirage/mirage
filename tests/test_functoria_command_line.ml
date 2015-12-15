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


(* TODO:
   a test for each subcommand
   a test for the top-level parsing
   tests for top-level --help and --version
   tests for config.ml file reading
 *)


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
  ]


let _ =
  run_test_tt_main suite
