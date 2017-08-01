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

open Functoria

(** {1 Useful module implementations} *)

val noop: job impl
(** [noop] is an implementation of {!Functoria.job} that holds no
    state, does nothing and has no dependency. *)

type argv
(** The type for command-line arguments, similar to the usual
    [Sys.argv]. *)

val argv: argv typ
(** [argv] is a value representing {!argv} module types. *)

val sys_argv: argv impl
(** [sys_argv] is a device providing command-line arguments by using
    {!Sys.argv}. *)

val keys: argv impl -> job impl
(** [keys a] is an implementation of {!Functoria.job} that holds the
    parsed command-line arguments. *)

type info
(** The type for application about the application being built. *)

val info: info typ
(** [info] is a value representing {!info} module types. *)

val app_info: ?type_modname:string -> ?gen_modname:string -> unit -> info impl
(** [app_info] is the module implementation whose state contains all
    the information available at configure-time. The type of the
    generated value lives in the module [type_modname]: if not set, it
    is [Functoria_info]. The value is stored into a generated module
    name [gen_modname]: if not set, it is [Info_gen]. *)

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

(** [Make] is an helper to generate new a application builder with the
    custom constructs defined by {!S}. *)
module Make (P: S): sig

  open Functoria

  val register:
    ?packages:package list ->
    ?keys:key list ->
    ?init:job impl list ->
    string -> job impl list -> unit
  (** [register name jobs] registers the application named by [name]
      which will execute the given [jobs]. Same optional arguments as
      {!Functoria.foreign}.

      [init] is the list of job to execute before anything else (such
      as command-line argument parsing, log reporter setup, etc.). The
      jobs are always executed in the sequence specified by the
      caller. *)

  val run: unit -> unit
  (** Run the application builder. This should be called exactly once
      to run the application builder: command-line arguments will be
      parsed, and some code will be generated and compiled. *)

  val run_with_argv:
    ?help_ppf:Format.formatter -> ?err_ppf:Format.formatter ->
    string array -> unit
  (** [run_with_argv a] is the same as {!run} but parses [a] instead
      of the process command line arguments. It also allows to set
      the error and help channels using [help_ppf] and [err_ppf]. *)
end

module type DSL = module type of struct include Functoria end
(** The signature of Functoria-like DSLs. *)

(** {1 Misc} *)

(** Name helpers. *)
module Name: sig

  val ocamlify: string -> string
  (** [ocamlify n] is an OCaml identifier looking very much like [n],
      but where invalid characters have been removed or replaced: all
      characters outside of ['a'-'z''A'-'Z''0''9''_''-'], and
      replacing '-' with '_'.  If the resulting string starts with a
      digit or is empty then it raises [Invalid_argument]. *)

  val create: string -> prefix:string -> string
  (** [name key ~prefix] is an deterministic name starting by
      [prefix]. The name is derived from [key].  *)

end

(** Code generation helpers. *)
module Codegen: sig

  val generated_header: unit -> string

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
