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

(** {1 Usefull module implementations} *)

val noop: job impl
(** [noop] is an implementation of {!Functioria.job} that hold no
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

val export_info: info impl
(** [export_info] is the module implementation whose state contins all
    the information available at configure-time and run-time.  *)

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

  val version: string
  (** Version of the custom DSL. *)

  val driver_error: string -> string
  (** [driver_error s] is the message given to the user when the
      the configurable [s] doesn't initialize correctly. *)

  val argv: argv impl
  (** [argv] is the device used to read the full list of command-line
      arguments. *)

  val create: job impl list -> job impl
  (** [create jobs] is the top-level job in the custom DSL which will
      execute the given list of [job]. *)

end

(** [Make] is an helper to generate new a application builder with the
    custom constructs defined by {!S}. *)
module Make (P: S): sig

  open Functoria

  val register:
    ?packages:string list ->
    ?libraries:string list ->
    ?keys:key list ->
    string -> job impl list -> unit
  (** [register name jobs] registers the application named by [name]
      which will executes the given [jobs]. Same optinal arguments as
      {!Functoria.foreign}.  *)

  val get_base_context: unit -> context
  (** [get_base_context ()] returns a subset of the parsed keys which
      are part of the base configuration of the DSL. This functions
      should be avoided as it exposes the internal parsing context.

      @deprecated Use the regular key mechanism.
  *)

  val run: unit -> unit
  (** Run the application builder. This should be called exactly once
      to run the application builder: command-line argument will be
      parsed, and some code will be generated and compiled. *)

end

module Name: sig
  (** {1 Name helpers} *)

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

module Cmd: sig
  (** {1 Shell command helpers.

      FIXME: replace by [Bos]. *)

  val exists: string -> bool
  (** [exists cmd] is [true] if the command [cmd] is available in {i
      $PATH}. *)

  val run: ?redirect:bool ->
    ('a, unit, string, (unit, string) Rresult.result) format4 -> 'a

  val remove: string -> unit

  val with_file: string -> (Format.formatter -> 'a) -> 'a

end

module Log: sig
  (** {1 Console logging helpers}

      FIXME: replace by [Bos]. *)

  val blue: string Fmt.t
  val yellow: string Fmt.t
  val red: string Fmt.t
  val green: string Fmt.t

  val error:
    ('a, Format.formatter, unit, ('b, string) Rresult.result) format4 -> 'a
    (** [error] display an error on the console. *)

  val info: ('a, Format.formatter, unit, unit) format4 -> 'a

end

module Codegen: sig

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
