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

open Functoria_dsl

type subconf = <
  name: string ;
  module_name: string ;
  keys: Key.t list ;
  packages: string list Key.value ;
  libraries: string list Key.value ;
  connect : Info.t -> string -> string list -> string ;
  configure: Info.t -> unit ;
  clean: Info.t -> unit ;
>

type description =
  | If of bool Key.value
  | Impl of subconf
  | App

type label =
  | Parameter of int
  | Dependency of int
  | Condition of [`Else | `Then]

type t
type vertex

module Tbl : Hashtbl.S with type key = vertex

val create : _ impl -> t
(** [create impl] creates a graph based [impl]. *)

val push_if : t -> t

val remove_partial_app : t -> t

val normalize : t -> t
(** [normalize g] normalize the graph [g] by
    - Pushing the [If] vertices up.
    - Removing the [App] nodes.
*)

val eval : ?partial:bool -> t -> t
(** [eval g] will removes all the [If] vertices by
    trying to resolve the keys.

    If [partial] is [true], then it will only evaluate
    [If] vertices which condition is resolved.
*)

val is_fully_reduced : t -> bool
(** [is_fully_reduced g] is true if [g] contains only
    [Impl] nodes. *)

val iter : t -> (vertex -> unit) -> unit
(** [iter g f] applies [f] on each vertex of [g] in topological order. *)

val find_root : t -> vertex
(** [find_root g] returns the only vertex of [g] that has no predecessors. *)

val explode :
  t -> vertex ->
  [ `App of vertex * vertex list
  | `If of bool Key.value * vertex * vertex
  | `Impl of subconf
       * [> `Args of vertex list ]
       * [> `Deps of vertex list ] ]
(** [explode g v] deconstructs the vertex [v] in the graph [g]
    into it's possible components.
    It also checks that the local invariants are respected. *)

val collect :
  (module Functoria_misc.Monoid with type t = 'ty) ->
  (description -> 'ty) -> t -> 'ty
(** [collect (module M) f g] collects the content of [f v] for
    each node [v] in [g]. *)

val pp : t Fmt.t
(** Textual representation of the graph. *)

val pp_dot : t Fmt.t
(** Dot representation of the graph. *)
