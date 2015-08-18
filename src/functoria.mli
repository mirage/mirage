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

module Key = Functoria_key

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
class type ['ty] configurable = object ('self)

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

  method connect : string -> string list -> string option
  (** Return the function call to connect at runtime with the device. *)

  method configure: unit
  (** Configure the device. *)

  method clean: unit
  (** Clean all the files generated to use the device. *)

  method update_path: string -> 'self
  (** [t#update_path root] prefixes all the path appearing in [t] with
      the the prefix [root]. *)

end

val impl: 'a configurable -> 'a impl
(** Extend the library with an external configuration. *)


class dummy_conf : object ('self)
  method libraries : string list
  method packages : string list
  method keys : Key.t list
  method connect : string -> string list -> string option
  method configure : unit
  method clean : unit
  method update_path : string -> 'self
end

(** {2 DSL extensions} *)

type t
(** A configuration. *)

val name : t -> string
(** The name of this configuration. *)

val root : t -> string
(** Root directory of the configuration. *)

val custom : t -> job configurable
(** The custom DSL plugin used by this configuration. *)

val add_to_opam_packages: string list -> unit
(** Add some base OPAM package to install *)

val packages: t -> string list
(** List of OPAM packages to install for this project. *)

val add_to_ocamlfind_libraries: string list -> unit
(** Link with the provided additional libraries. *)

val libraries: t -> string list
(** List of ocamlfind libraries. *)

val add_to_keys: Key.t list -> unit
(** Add new keys. *)

val keys: t -> Key.Set.t
(** Set of keys. *)

val primary_keys: t -> Key.Set.t
(** List of keys that are used for implementation selection. *)

module type PROJECT = sig

  val application_name : string

  val version : string

  val driver_error : string -> string

  class conf : t Lazy.t -> [job] configurable

end

module type CONFIG = sig
  module Project : PROJECT

  val dummy_conf : t

  val load: string option -> (t, string) Rresult.result
  (** Read a config file. If no name is given, search for use
      [config.ml]. *)

  (** {2 Jobs} *)

  val register:
    ?keys:Key.t list -> string -> job impl list -> unit
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

  val configure: t -> unit
  (** Generate some code to create a value with the right
      configuration settings. *)

  val clean: t -> unit
  (** Remove all the autogen files. *)

  val build: t -> unit
  (** Call [make build] in the right directory. *)

end


module Make (Project:PROJECT) : CONFIG with module Project = Project
