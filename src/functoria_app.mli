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

val noop: job impl
(** [noop] is a job that does nothing, has no dependency and returns
      [()] *)

(** {1 Argv device} *)

type argv
(** The type for command-line arguments, similar to the usual
    [Sys.argv]. *)

val argv: argv typ
(** [argv] is a value representing {!argv} module types. *)

val sys_argv: argv impl
(** [sys_argv] is a device providing command-line arguments by using
    {!Sys.argv}. *)

(** {1 Configuration Key} *)

val keys: argv impl -> job impl
(** [keys a] is job with keys set taking an [argv] device, calls
    cmdliner and sets up keys. *)

(** {1 Information about the Application} *)

type info
(** The type for application about the application being built. *)

val info: info typ
(** [info] is a value representing {!info} module types. *)

val export_info: info impl
(** [export_info] is the module implementation whose state contins all
    the information available at configure-time and run-time.  *)

(** [S] is the signature that custom application builders have to
    provide. *)
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

(** [Make] is an helper to generate new application builders with
    custom constructs, defined by {!S}. *)
module Make (P: S): sig

  open Functoria

  val register:
    ?packages:string list ->
    ?libraries:string list ->
    ?keys:Key.t list ->
    string -> job impl list -> unit
  (** [register name jobs] registers the application named by [name]
      which will executes the given [jobs]. Same optinal arguments as
      {!Functoria.foreign}.  *)

  val get_base_keys: unit -> Key.parsed
  (** [get_base_keys ()] returns a subset of the parsed keys which are
      part of the base configuration of the DSL. This functions should
      be avoided as it exposes some library internals.

      @deprecated Use the regular key mechanism.
  *)

  val run: unit -> unit
  (** Run the application builder. Should only be used by the host
      specialized DSL.  *)

end
