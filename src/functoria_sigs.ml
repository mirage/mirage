(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
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

(** All the functoria signatures you would ever want. *)

(** Configuration keys. *)
module type KEY = sig

  type 'a key
  type 'a value

  type t = Any : 'a key -> t

  module Set : Set.S with type elt = t

end

(** The core DSL. *)
module type CORE = sig

  (** {2 Module combinators} *)

  type _ typ =
    | Type: 'a -> 'a typ
    | Function: 'a typ * 'b typ -> ('a -> 'b) typ
  (** The type of values representing module types. *)

  val typ: 'a -> 'a typ
  (** Create a new type. *)

  val (@->): 'a typ -> 'b typ -> ('a -> 'b) typ
  (** Construct a functor type from a type and an existing functor
      type. This corresponds to prepending a parameter to the list of
      functor parameters. For example,

      {[ kv_ro @-> ip @-> kv_ro ]}

      describes a functor type that accepts two arguments -- a kv_ro and
      an ip device -- and returns a kv_ro.
  *)

  type 'a impl
  (** The type of values representing module implementations. *)

  val ($): ('a -> 'b) impl -> 'a impl -> 'b impl
  (** [m $ a] applies the functor [m] to the module [a]. *)

  (** {2 Key usage} *)

  (** Key creation and manipulation. *)
  module Key : KEY

  val if_impl : bool Key.value -> 'a impl -> 'a impl -> 'a impl
  (** [if_impl v impl1 impl2] is [impl1] if [v] is resolved to true and [impl2] otherwise. *)

  val switch :
    default:'a impl ->
    ('b * 'a impl) list ->
    'b Key.value ->
    'a impl
  (** [switch ~default l v] choose the implementation in [l] corresponding to the value [v].
      The [default] implementation is chosen if no value match.
  *)

  (** {2 Implementations constructors} *)

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
  (** Representation of a job. *)

  (** {2 DSL extension} *)

  (** Information available during configuration. *)
  module Info : sig
    type t

    val name : t -> string
    val root : t -> string
    val libraries : t -> Functoria_misc.StringSet.t
    val packages : t -> Functoria_misc.StringSet.t
    val keys : t -> Key.Set.t
  end

  type any_impl = Any : _ impl -> any_impl
  (** Type of an implementation, with its type variable hidden. *)

  val hide : _ impl -> any_impl
  (** Hide the type variable of an implementation. Useful for dependencies. *)

  (** Signature for configurable devices. *)
  class type ['ty] configurable = object

    method ty : 'ty typ
    (** Type of the device. *)

    method name: string
    (** Return the unique variable name holding the state of the device. *)

    method module_name: string
    (** Return the name of the module implementing the device. *)

    method packages: string list Key.value
    (** Return the list of OPAM packages which needs to be installed to
        use the device. *)

    method libraries: string list Key.value
    (** Return the list of ocamlfind libraries to link with the
        application to use the device. *)

    method keys: Key.t list
    (** Return the list of keys to configure the device. *)

    method connect : Info.t -> string -> string list -> string
    (** Return the function call to connect at runtime with the device. *)

    method configure: Info.t -> (unit, string) Rresult.result
    (** Configure the device. *)

    method clean: Info.t -> (unit, string) Rresult.result
    (** Clean all the files generated to use the device. *)

    method dependencies : any_impl list
    (** The list of dependencies that must be initalized before this module. *)

  end

  val impl: 'a configurable -> 'a impl
  (** Extend the library with an external configuration. *)

  (** The base configurable pre-defining many methods. *)
  class base_configurable : object
    method libraries : string list Key.value
    method packages : string list Key.value
    method keys : Key.t list
    method connect : Info.t -> string -> string list -> string
    method configure : Info.t -> (unit, string) Rresult.result
    method clean : Info.t -> (unit, string) Rresult.result
    method dependencies : any_impl list
  end

end

(** A complete DSL, with configuration functions. *)
module type S = sig

  include CORE

  val register:
    ?keys:Key.t list -> ?libraries:string list -> ?packages:string list ->
    string -> job impl list -> unit
  (** [register name jobs] registers the application named by [name]
      which will executes the given [jobs].
      @param keys passes user-defined config keys (which can be set on the command-line) *)

end

(** A configuration engine. For internal use. *)
module type CONFIG = sig
  type info

  val name : string
  (** Name of the project. *)

  val version : string
  (** Version of the project. *)

  (** {2 Configuration} *)

  type t
  (** A configuration. *)

  val base_keys : unit Cmdliner.Term.t
  (** Base keys provided by the specialized DSL. *)

  val load: string option -> (t, string) Rresult.result
  (** Read a config file. If no name is given, search for use
      [config.ml]. *)

  val switching_keys : t -> unit Cmdliner.Term.t

  val eval : t -> <
      build : info -> (unit, string) Rresult.result;
      clean : info -> (unit, string) Rresult.result;
      configure :
        info ->
        no_opam:bool ->
        no_depext:bool ->
        no_opam_version:bool ->
        (unit, string) Rresult.result;
      info : info Cmdliner.Term.t;
      describe :
        dotcmd:string -> dot:bool -> eval:bool ->
        string option -> unit;
    >

end
