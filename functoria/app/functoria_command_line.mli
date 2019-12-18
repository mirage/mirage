(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
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

(** Functions for reading various options from a command line. *)

val setup_log : unit Cmdliner.Term.t
val config_file : (Fpath.t -> unit) -> unit Cmdliner.Term.t
val build_dir: (Fpath.t -> unit) -> unit Cmdliner.Term.t
val output: string option Cmdliner.Term.t

val read_full_eval : string array -> bool option
(** [read_full_eval argv] reads the --eval option from [argv]; the return
    value is [None] if option is absent in [argv]. *)

type 'a configure_args = {
  result: 'a;
  output: string option;
}
(** A value of type [configure_args] is the result of parsing the arguments of
    a [configure] subcommand. *)

type 'a describe_args = {
  result: 'a;
  dotcmd: string;
  dot: bool;
  output: string option;
}
(** A value of type [describe_args] is the result of parsing the arguments to
    a [describe] subcommand.

    The [result] field holds the result of parsing the "additional" arguments
    whose specification is passed as the [describe] argument to
    {!parse_args}. *)

type 'a action =
    Configure of 'a configure_args
  | Describe of 'a describe_args
  | Build of 'a
  | Clean of 'a
  | Help
(** A value of type [action] is the result of parsing command-line arguments using
    [parse_args]. *)

val pp_action: 'a Fmt.t -> 'a action Fmt.t
(** [pp_action] is the pretty-printer for actions. *)

open Cmdliner.Term

val parse_args :
  ?help_ppf:Format.formatter ->
  ?err_ppf:Format.formatter ->
  name:string -> version:string ->
  configure:'a t ->
  describe:'a t ->
  build:'a t ->
  clean:'a t ->
  help:_ t ->
  string array ->
  'a action result
(** Parse the functoria command line.  The arguments to [~configure],
    [~describe], etc., describe extra command-line arguments that should be
    accepted by the corresponding subcommands.  The full argument
    specification is as follows:

      name configure [-v|--verbose]
                     [--color=(auto|always|never)]
                     [extra arguments]
      name describe [--eval]
                    [-v|--verbose]
                    [--color=(auto|always|never)]
                    [-o FILE | --output=FILE]
                    [--dot-command=COMMAND]
                    [--dot]
                    [extra arguments]
      name build [-v|--verbose]
                 [--color=(auto|always|never)]
                 [extra arguments]
      name clean [-v|--verbose]
                 [--color=(auto|always|never)]
                 [extra arguments]
      name help [-v|--verbose]
                [--color=(auto|always|never)]
                [--man-format=(groff|pager|plain)]
                [configure|describe|build|clean|help|topics]
                [extra arguments]
      name [-v|--verbose]
           [--color=(auto|always|never)]

    There are no side effects, save for the printing of usage messages and
    other help when either the 'help' subcommand or no subcommand is specified. *)
