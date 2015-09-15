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

(** Core functoria DSL *)

open Functoria_misc

(** {2 Module combinators} *)

(** The type of values representing module types. *)
type _ typ =
  | Type: 'a -> 'a typ
  | Function: 'a typ * 'b typ -> ('a -> 'b) typ

val typ: 'a -> 'a typ
(** Create a new type. *)

val (@->): 'a typ -> 'b typ -> ('a -> 'b) typ
(** Construct a functor type from a type and an existing functor
    type. This corresponds to prepending a parameter to the list of
    functor parameters. For example:

    {[ kv_ro @-> ip @-> kv_ro ]}

    This describes a functor type that accepts two arguments - a [kv_ro] and
    an [ip] device - and returns a [kv_ro].
*)

type 'a impl
(** The type of values representing module implementations. *)

val ($): ('a -> 'b) impl -> 'a impl -> 'b impl
(** [m $ a] applies the functor [m] to the module [a]. *)

(** Type of an implementation, with its type variable hidden. *)
type any_impl = Any : _ impl -> any_impl

val hidden : _ impl -> any_impl
(** Hide the type variable of an implementation. Useful for dependencies. *)

(** {2 Keys} *)

(** Key creation and manipulation. *)
module Key = Functoria_key

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

(** {2 Declaring new modules} *)

val foreign:
  ?keys:Key.t list ->
  ?libraries:string list ->
  ?packages:string list ->
  ?dependencies:any_impl list ->
  string -> 'a typ -> 'a impl
(** [foreign name typ] states that the module named by [name] has the
    module type [typ].
    @param libraries The ocamlfind libraries needed by this module.
    @param packages The opam packages needed by this module.
    @param keys The keys related to this module.
    @param dependencies The data-dependencies needed by this module. You must use {!hide} to pass an arbitrary implementation.
*)

type job
(** Type for job values. *)

val job: job typ
(** Representation of a job. *)

(** {2 DSL extension} *)

(** Information available during configuration. *)
module Info : sig

  type t
  (** Configuration information for the whole project. *)

  val name : t -> string
  (** Name of the project *)

  val root : t -> string
  (** Directory in which the configuration is done. *)

  val libraries : t -> StringSet.t
  (** Ocamlfind libraries needed by the project. *)

  val packages : t -> StringSet.t
  (** OPAM packages needed by the project. *)

  val keys : t -> Key.Set.t
  (** Keys declared by the project. *)

  val create :
    ?keys:Key.Set.t ->
    ?libraries:StringSet.t ->
    ?packages:StringSet.t ->
    name:string ->
    root:string -> t

end

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
  (** The list of dependencies that must be initalized before this device.
      You must use {!hide} to pass an arbitrary implementation.
  *)

end

val impl: 'a configurable -> 'a impl
(** Create an implementation based on a specified device. *)

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

(** {3 Sharing} *)

val hash : 'a impl -> int
(** Hash an implementation. *)

val equal : 'a impl -> 'a impl -> bool

module ImplTbl : Hashtbl.S with type key = any_impl
(** Hashtbl of implementations. *)

(** {3 Misc} *)

val explode : 'a impl ->
  [ `App of any_impl * any_impl
  | `If of bool Key.value * 'a impl * 'a impl
  | `Impl of 'a configurable ]
