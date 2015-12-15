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

val read_log_level : string array -> Functoria_misc.Log.level
(** [read_log_level argv] reads -v and --verbose options from [argv] and
    builds a {!Log.level} value according to the number of times the flags
    occur:
     * 0 occurrences: WARN
     * 1 occurrence: INFO
     * 2+ occurrences: DEBUG
*)

val read_colour_option : string array -> Fmt.style_renderer option
(** [read_colour_option argv] reads the --color option from [argv] and builds
    a {!Fmt.style_renderer} value that depends on the argument of the option:
     * --color=auto: None
     * --color=always: Some `Ansi_tty
     * --color=never: Some `None
*)

val read_config_file : string array -> string option
(** [read_config_file argv] reads the -f or --file option from [argv] and
    returns the argument of the option. *)

val read_full_eval : string array -> bool
(** [read_full_eval argv] reads the --eval option from [argv]; the return
    value indicates whether the option is present in [argv]. *)

type 'a config_args = {
  evaluated: 'a;
  no_opam: bool;
  no_depext: bool;
  no_opam_version: bool
}
(** A value of type [config_args] is the result of parsing the arguments to a
    [configure] subcommand.

    The [result] field holds the result of parsing the "additional" arguments
    whose specification is passed as the [configure] argument to
    {!parse_args}. *)

type 'a describe_args = {
  evaluated: 'a;
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
    Configure of 'a config_args
  | Describe of 'a describe_args
  | Build of 'a
  | Clean of 'a
  | Help
(** A value of type [action] is the result of parsing command-line arguments using
    [parse_args]. *)

open Cmdliner.Term

val configure : 'a t -> 'a action t * info
val build : 'a t -> 'a action t * info
val help : 'a t -> 'b action t * info
val describe : 'a t -> 'a action t * info
val clean : 'a t -> 'a action t * info
val default : name:string -> version:string -> 'a t * info
