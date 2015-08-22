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
open Functoria_misc

module Key = Functoria_key

module Info : sig
  type t

  val name : t -> string
  val root : t -> string
  val libraries : t -> StringSet.t
  val packages : t -> StringSet.t
  val keys : t -> Key.Set.t
end

(** {2 Module combinators} *)

type 'a typ =
  | Type: 'a -> 'a typ
  | Function: 'a typ * 'b typ -> ('a -> 'b) typ
  (** The type of values representing module types. *)

val (@->): 'a typ -> 'b typ -> ('a -> 'b) typ
(** Construct a functor type from a type and an existing functor
    type. This corresponds to prepending a parameter to the list of
    functor parameters. For example,

    {[ kv_ro @-> ip @-> kv_ro ]}

    describes a functor type that accepts two arguments -- a kv_ro and
    an ip device -- and returns a kv_ro.
*)

val typ: 'a -> 'a typ
(** Return the module signature of a given implementation. *)


type 'a impl
(** The type of values representing module implementations. *)

val ($): ('a -> 'b) impl -> 'a impl -> 'b impl
(** [m $ a] applies the functor [m] to the module [a]. *)

val foreign:
  ?keys:Key.t list ->
  ?libraries:string list ->
  ?packages:string list -> string -> 'a typ -> 'a impl
(** [foreign name libs packs constr typ] states that the module named
    by [name] has the module type [typ]. If [libs] is set, add the
    given set of ocamlfind libraries to the ones loaded by default. If
    [packages] is set, add the given set of OPAM packages to the ones
    loaded by default. *)


type job
(** Type for job values. *)

val job: job typ
(** Reprensention of a job. *)



(** {2 Implementation of new devices} *)

(** Signature for configurable devices. *)
class type ['ty] configurable = object

  method ty : 'ty typ
  (** Type of the device. *)

  method name: string
  (** Return the unique variable name holding the state of the device. *)

  method module_name: string
  (** Return the name of the module implementing the device. *)

  method packages: string list
  (** Return the list of OPAM packages which needs to be installed to
      use the device. *)

  method libraries: string list
  (** Return the list of ocamlfind libraries to link with the
      application to use the device. *)

  method keys: Key.t list
  (** Return the list of keys to configure the device. *)

  method connect : Info.t -> string -> string list -> string option
  (** Return the function call to connect at runtime with the device. *)

  method configure: Info.t -> unit
  (** Configure the device. *)

  method clean: unit
  (** Clean all the files generated to use the device. *)

  method dependencies : job impl list
  (** The list of dependencies that must be initalized before this module. *)

end

val impl: 'a configurable -> 'a impl
(** Extend the library with an external configuration. *)


class base_configurable : object
  method libraries : string list
  method packages : string list
  method keys : Key.t list
  method connect : Info.t -> string -> string list -> string option
  method configure : Info.t -> unit
  method clean : unit
  method dependencies : job impl list
end

(** {2 DSL extensions} *)

module type PROJECT = sig

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
      build : unit;
      clean : unit;
      configure : unit;
      keys : unit Cmdliner.Term.t
    >
end


module Make (Project:PROJECT) : CONFIG with module Project = Project
