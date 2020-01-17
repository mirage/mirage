(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
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

(** Application builder. *)

(** {1 Builders} *)

(** [S] is the signature that application builders have to provide. *)
module type S = sig

  open Functoria

  val prelude: string
  (** Prelude printed at the beginning of [main.ml].

      It should put in scope:

      - a [run] function of type ['a t -> 'a]
      - a [return] function of type ['a -> 'a t]
      - a [>>=] operator of type ['a t -> ('a -> 'b t) -> 'b t]
  *)

  val name: string
  (** Name of the custom DSL. *)

  val packages: package list
  (** The packages to load when compiling the configuration file. *)

  val ignore_dirs: string list
  (** Directories to ignore when compiling the configuration file. *)

  val version: string
  (** Version of the custom DSL. *)

  val create: job impl list -> job impl
  (** [create jobs] is the top-level job in the custom DSL which will
      execute the given list of [job]. *)

end

module Make (P: S): sig

  open Functoria

  (** Configuration builder: stage 1 *)

  val run: unit -> unit
  (** Run the configuration builder. This should be called exactly once
      to run the configuration builder: command-line arguments will be
      parsed, and some code will be generated and compiled. *)

  val run_with_argv:
    ?help_ppf:Format.formatter -> ?err_ppf:Format.formatter ->
    string array -> unit
  (** [run_with_argv a] is the same as {!run} but parses [a] instead
      of the process command line arguments. It also allows to set
      the error and help channels using [help_ppf] and [err_ppf]. *)


  (** Configuration module: stage 2 *)

  val register:
    ?packages:package list ->
    ?keys:abstract_key list ->
    ?init:job impl list ->
    string -> job impl list -> unit
  (** [register name jobs] registers the application named by [name]
      which will execute the given [jobs]. Same optional arguments as
      {!Functoria.foreign}.

      [init] is the list of job to execute before anything else (such
      as command-line argument parsing, log reporter setup, etc.). The
      jobs are always executed in the sequence specified by the
      caller. *)
end


module type DSL = module type of struct include Functoria end
(** The signature of Functoria-like DSLs. *)

(** {1 Misc} *)

(** Code generation helpers. *)
module Codegen: sig

  val generated_header: ?argv:string array -> unit -> string

  val append:
    Format.formatter -> ('a, Format.formatter, unit, unit, unit, unit) format6 -> 'a

  val newline: Format.formatter -> unit

  val set_main_ml: string -> unit
  (** Define the current main file. *)

  val append_main: ('a, Format.formatter, unit, unit, unit, unit) format6 -> 'a
  (** Add some string to [main.ml]. *)

  val newline_main: unit -> unit
  (** Add a newline to [main.ml]. *)

end
