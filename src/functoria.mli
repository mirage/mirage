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

(** Configuration library *)

(** Core functoria DSL *)
module Dsl: module type of struct include Functoria_dsl end

(** Various generic devices. *)
module Devices: sig

  open Dsl

  (** {2 Noop} *)

  val noop: job impl
  (** [noop] is a job that does nothing, has no dependency and returns
      [()] *)

  (** {2 Argv device} *)

  type argv
  (** The type for command-line arguments, similar to the usual [argv]. *)

  val argv: argv typ
  (** The type for {!argv} implementations. *)

  val sys_argv: argv impl
  (** [sys_argv] is a device providing command-line arguments by using
      {!Sys.argv}. *)

  (** {2 Key device} *)

  val keys: argv impl -> job impl
  (** [keys a] is job with keys set taking an [argv] device, calls cmdliner and sets up keys. *)

  (** {2 Information device} *)

  type info
  val info: info typ

  val export_info: info impl
  (** Export all the information available at configure time to runtime.
      It produces, at runtime, a {!Functoria_info.info}.
  *)

end

(** [CUSTOM] is the signature for custom DSL. *)
module type CUSTOM = sig

  open Dsl

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

  val argv: Devices.argv Functoria_dsl.impl
  (** [argv] is the device used to read the full list of command-line
      arguments. *)

  val config: job impl list -> job impl
  (** [config jobs] is the device configuration the custom DSL, given
      a list of configuration [jobs].

      FIXME(thomas): I am not sure to understand that signature.
*)

end

(** Create a configuration engine for a custom DSL. *)
module Make (P: CUSTOM): sig

  open Dsl

  val register:
    ?keys:Key.t list ->
    ?libraries:string list ->
    ?packages:string list ->
    string -> job impl list -> unit
  (** [register name jobs] registers the application named by [name]
      which will executes the given [jobs].

      @param libraries The ocamlfind libraries needed by this module.
      @param packages The opam packages needed by this module.
      @param keys The keys related to this module.
  *)

  val get_base_keymap: unit -> Key.map
  (** [get_base_keymap ()] returns the keymap containing the keys of
      the specialized DSL. This functions should be avoided.

      @deprecated Use the regular key mechanism.
  *)

  val launch: unit -> unit
  (** Launch the cmdliner application. Should only be used by the host
      specialized DSL.  *)

end

module type S = module type of struct include Dsl end
module type KEY = module type of struct include Dsl.Key end
