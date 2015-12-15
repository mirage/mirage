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

val read_log_level : string array -> Functoria_misc.Log.level
val read_colour_option : string array -> Fmt.style_renderer option
val read_config_file : string array -> string option
val read_full_eval : string array -> bool

type 'a config_args = {
  evaluated: 'a;
  no_opam: bool;
  no_depext: bool;
  no_opam_version: bool
}

type 'a describe_args = {
  evaluated: 'a;
  dotcmd: string;
  dot: bool;
  output: string option;
}

type 'a action =
    Configure of 'a config_args
  | Describe of 'a describe_args
  | Build of 'a
  | Clean of 'a
  | Nothing

val configure : 'a Cmdliner.Term.t ->
  'a action Cmdliner.Term.t * Cmdliner.Term.info
val build : 'a Cmdliner.Term.t ->
  'a action Cmdliner.Term.t * Cmdliner.Term.info
val help : 'a Cmdliner.Term.t ->
  'b action Cmdliner.Term.t * Cmdliner.Term.info
val describe : 'a Cmdliner.Term.t ->
  'a action Cmdliner.Term.t * Cmdliner.Term.info
val clean : 'a Cmdliner.Term.t ->
  'a action Cmdliner.Term.t * Cmdliner.Term.info
val default : name:string -> version:string ->
  'a Cmdliner.Term.t * Cmdliner.Term.info
