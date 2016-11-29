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

(** Graph engine *)

open Functoria

type subconf = <
  name       : string;
  module_name: string;
  keys       : key list;
  packages   : package list value ;
  connect    : Info.t -> string -> string list -> string;
  build      : Info.t -> (unit, [ `Msg of string ]) Rresult.result;
  configure  : Info.t -> (unit, [ `Msg of string ]) Rresult.result;
  clean      : Info.t -> (unit, [ `Msg of string ]) Rresult.result;
>
(** A subset of {!configurable} with neither polymorphism nor recursion. *)

type t
type vertex

module If: sig
  type path
end

(** The description of a vertex *)
type label =
  | If of If.path value
  | Impl of subconf
  | App

module Tbl: Hashtbl.S with type key = vertex

val create: _ impl -> t
(** [create impl] creates a graph based [impl]. *)

val normalize: t -> t
(** [normalize g] normalize the graph [g] by removing the [App] vertices. *)

val simplify: t -> t
(** [simplify g] simplifies the graph so that it's easier to read for humans. *)

val eval: ?partial:bool -> context:context -> t -> t
(** [eval ~keys g] will removes all the [If] vertices by resolving the
    keys using [keys]. It will then call {!normalize}

    If [partial] is [true], then it will only evaluate [If] vertices
    which condition is resolved.
*)

val is_fully_reduced: t -> bool
(** [is_fully_reduced g] is true if [g] contains only
    [Impl] vertices. *)

val fold: (vertex -> 'a -> 'a) -> t -> 'a -> 'a
(** [fold f g z] applies [f] on each vertex of [g] in topological order. *)

val find_all: t -> (label -> bool) -> vertex list
(** [find_all g p] returns all the vertices in [g] such as [p v] is true. *)

val find_root: t -> vertex
(** [find_root g] returns the only vertex of [g] that has no predecessors. *)

val explode:
  t -> vertex ->
  [ `App of vertex * vertex list
  | `If of If.path value * (If.path * vertex) list
  | `Impl of subconf
             * [> `Args of vertex list ]
             * [> `Deps of vertex list ] ]
(** [explode g v] deconstructs the vertex [v] in the graph [g]
    into it's possible components.
    It also checks that the local invariants are respected. *)

val collect:
  (module Functoria_misc.Monoid with type t = 'ty) ->
  (label -> 'ty) -> t -> 'ty
(** [collect (module M) f g] collects the content of [f v] for
    each vertex [v] in [g]. *)

val hash: vertex -> int

val pp: t Fmt.t
(** Textual representation of the graph. *)

val pp_dot: t Fmt.t
(** Dot representation of the graph. *)
