(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
 * Copyright (c) 2015-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
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

module Key = Functoria_key
module Device = Functoria_device
module Package = Functoria_package
module Info = Functoria_info
module Type = Functoria_type
open Rresult

type 'a t
(** The type for values representing module implementations of type ['a]. *)

type abstract
(** The type for untyped {!t}. *)

type 'a device = ('a, abstract) Device.t
(** The type for device whose dependencies have typ {!abstract}. *)

val abstract : 'a t -> abstract
(** [abstract i] is [i] with its type erased. *)

val pp : 'a t Fmt.t
(** [pp] is the pretty-printer for module implementations. *)

val pp_abstract : abstract Fmt.t
(** [pp_asbtrat] is the pretty-printer the abstract module implementations. *)

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
  ?keys:Key.t list ->
  ?extra_deps:abstract list ->
  ?connect:(Info.t -> string -> string list -> string) ->
  ?configure:(Info.t -> (unit, R.msg) result) ->
  ?build:(Info.t -> (unit, R.msg) result) ->
  ?clean:(Info.t -> (unit, R.msg) result) ->
  string ->
  'a Type.t ->
  'a t
(** [v ...] is [of_device @@ Device.v ...] *)

val main :
  ?packages:Package.t list ->
  ?packages_v:Package.t list Key.value ->
  ?keys:Key.t list ->
  ?extra_deps:abstract list ->
  string ->
  'a Type.t ->
  'a t
(** [main ... name ty] is [v ... ~connect name ty] where [connect] is
    [<name>.start <args>] *)

(** {1 Useful module implementations} *)

val noop : Type.job t
(** [noop] is an implementation of {!Functoria.job} that holds no state, does
    nothing and has no dependency. *)

val sys_argv : Type.argv t
(** [sys_argv] is a device providing command-line arguments by using
    {!Sys.argv}. *)

val keys : Type.argv t -> Type.job t
(** [keys a] is an implementation of {!Functoria.job} that holds the parsed
    command-line arguments. *)

val app_info :
  ?opam_deps:(string * string) list ->
  ?gen_modname:string ->
  unit ->
  Type.info t
(** [app_info] is the module implementation whose state contains all the
    information available at configure-time. The value is stored into a
    generated module name [gen_modname]: if not set, it is [Info_gen]. *)

module Tbl : Hashtbl.S with type key = abstract
(** Hashtbl of implementations. *)

(** {1 Applications} *)

type 'b f_dev = { f : 'a. 'a device -> 'b }
(** The type for iterators on devices. *)

type 'a f_if = cond:bool Key.value -> then_:'a -> else_:'a -> 'a
(** The type for iterators in [if] nodes. *)

type 'a f_app = f:'a -> x:'a -> 'a
(** the type for iterators on [app] nodes. *)

val with_left_most_device : Key.context -> _ t -> 'a f_dev -> 'a
(** [with_left_most_device ctx t f] applies [f] on the left-most device in [f].
    [If] node are resolved using [ctx]. *)

val map :
  if_:'a f_if -> app:'a f_app -> dev:(deps:'a list -> 'a) f_dev -> 'b t -> 'a
(** [fold ~if ~app ~dev acc t] fold over [t]'s sub-components, by applying [if],
    [app] and [dev] to each corresponding kind of constructions. *)
