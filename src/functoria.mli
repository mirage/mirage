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

(** Configuration library. *)
open Rresult
open Functoria_misc

module Key = Functoria_key

include Functoria_sigs.DSL
  with module Key := Key

class base_configurable : object
  method libraries : string list
  method packages : string list
  method keys : Key.t list
  method connect : Info.t -> string -> string list -> string
  method configure : Info.t -> unit
  method clean : Info.t -> unit
  method dependencies : any_impl list
end

(** {2 DSL extensions} *)

module type PROJECT = sig

  val prelude : string

  val name : string

  val version : string

  val driver_error : string -> string

  val configurable :
    name:string -> root:string -> job impl list ->
    job configurable

end

module type CONFIG = sig
  module Project : PROJECT

  type t
  (** A configuration. *)

  (** {2 Jobs} *)

  val register:
    ?keys:Key.t list -> ?libraries:string list -> ?packages:string list ->
    string -> job impl list -> unit
  (** [register name jobs] registers the application named by [name]
      which will executes the given [jobs].
      @param keys passes user-defined config keys (which can be set on the command-line) *)


  (** {2 Project configuration} *)

  val manage_opam_packages: bool -> unit
  (** Tell Irminsule to manage the OPAM configuration
      (ie. install/remove missing packages). *)

  val no_opam_version_check: bool -> unit
  (** Bypass the check of opam's version. *)

  val no_depext: bool -> unit
  (** Skip installation of external dependencies. *)


  (** {2 Config manipulation} *)
  val dummy_conf : t

  val load: string option -> (t, string) Rresult.result
  (** Read a config file. If no name is given, search for use
      [config.ml]. *)

  val primary_keys : t -> unit Cmdliner.Term.t

  val eval : t -> <
      build : (unit, string) result;
      clean : (unit, string) result;
      configure : (unit, string) result;
      keys : unit Cmdliner.Term.t
    >
end


module Make (Project:PROJECT) : CONFIG with module Project = Project
