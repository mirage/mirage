(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2020 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2015-2020 Gabriel Radanne <drupyog@zoho.com>
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

type 'a t
(** The type for values representing module implementations of type ['a]. *)

type abstract
(** The type for untyped {!t}. *)

type 'a device = ('a, abstract) Device.t
(** The type for device whose dependencies have type {!type:abstract}. *)

val abstract : 'a t -> abstract
(** [abstract i] is [i] with its type erased. *)

val app_has_no_arguments : 'a t -> bool
(** [app_has_no_arguments i] is [true] if the argument list is empty and it is
    an application, [false] otherwise. *)

val pp : 'a t Fmt.t
(** [pp] is the pretty-printer for module implementations. *)

val pp_abstract : abstract Fmt.t
(** [pp_abstract] is the pretty-printer for abstract module implementations. *)

val pp_dot : abstract Fmt.t
(** [pp_dot] outputs the dot representation of module implementations. *)

val ( $ ) : ('a -> 'b) t -> 'a t -> 'b t
(** [m $ a] applies the functor [m] to the module [a]. *)

val if_ : bool Key.value -> 'a t -> 'a t -> 'a t
(** [if_t v t1 t2] is [t1] if [v] is resolved to true and [t2] otherwise. *)

val match_ : 'b Key.value -> default:'a t -> ('b * 'a t) list -> 'a t
(** [match_t v cases ~default] chooses the tementation amongst [cases] by
    matching the [v]'s value. [default] is chosen if no value matches. *)

val of_device : 'a device -> 'a t
(** [of_device t] is the tementation device [t]. *)

val v :
  ?packages:Package.t list ->
  ?packages_v:Package.t list Key.value ->
  ?runtime_args:Runtime_arg.t list ->
  ?keys:Key.t list ->
  ?extra_deps:abstract list ->
  ?connect:(Info.t -> string -> string list -> 'a Device.code) ->
  ?dune:(Info.t -> Dune.stanza list) ->
  ?configure:(Info.t -> unit Action.t) ->
  ?files:(Info.t -> Fpath.t list) ->
  string ->
  'a Type.t ->
  'a t
(** [v ...] is [of_device @@ Device.v ...] *)

val main :
  ?pos:string * int * int * int ->
  ?packages:Package.t list ->
  ?packages_v:Package.t list Key.value ->
  ?runtime_args:Runtime_arg.t list ->
  ?keys:Key.t list ->
  ?extra_deps:abstract list ->
  string ->
  'a Type.t ->
  'a t
(** [main ... name ty] is [v ... ~connect name ty] where [connect] is
    [<name>.start <args>] *)

module Tbl : Hashtbl.S with type key = abstract
(** Hashtbl of implementations. *)

(** {1 Applications} *)

type 'b f_dev = { f : 'a. 'a device -> 'b }
(** The type for iterators on devices. *)

val with_left_most_device : Context.t -> _ t -> 'a f_dev -> 'a
(** [with_left_most_device ctx t f] applies [f] on the left-most device in [f].
    [If] node are resolved using [ctx]. *)

val simplify : full:bool -> context:Context.t -> abstract -> abstract
(** [simplify ~full ~context impl] simplifies the implementation [impl]
    according to keys present in the [context].

    If [full] is [true], then the default values of keys are used in their
    absence. Otherwise, absent keys are left un-simplified. *)

val eval : context:Context.t -> abstract -> Device.Graph.t
(** [eval ~context impl] fully evaluates the implementation [impl] according to
    keys present in the [context]. It returns a graph composed only of devices.
*)

(** Collections *)

(** The description of a vertex *)
type label = If : _ Key.value -> label | Dev : _ Device.t -> label | App

val collect :
  (module Misc.Monoid with type t = 'ty) -> (label -> 'ty) -> abstract -> 'ty
(** [collect (module M) f g] collects the content of [f v] for each vertex [v]
    in [g]. *)
