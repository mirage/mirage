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

(** Implementation Graphs. *)

open DSL

type t

(* val pp_vertex : vertex Fmt.t *)

module If : sig
  type path
end

(** The description of a vertex *)
type label = If of If.path value | Dev : 'a device -> label | App

module Tbl : Hashtbl.S with type key = t

val create : _ impl -> t
(** [create impl] creates a graph based [impl]. *)

val normalize : t -> t
(** [normalize g] normalize the graph [g] by removing the [App] vertices. *)

(* val simplify : t -> t
 * (\** [simplify g] simplifies the graph so that it's easier to read for humans. *\) *)

val eval : ?partial:bool -> context:context -> t -> t
(** [eval ~keys g] will removes all the [If] vertices by resolving the keys
    using [keys]. It will then call {!normalize}

    If [partial] is [true], then it will only evaluate [If] vertices which
    condition is resolved. *)

val is_fully_reduced : t -> bool
(** [is_fully_reduced g] is true if [g] contains only [Dev] vertices. *)

(* val find_all : t -> (label -> bool) -> vertex list
 * (\** [find_all g p] returns all the vertices in [g] such as [p v] is true. *\) *)

type a_device = D : 'a device -> a_device

val devices : t -> a_device list

type dtree = {
  dev : a_device ;
  args : dtree list ;
  deps : dtree list ;
  id : int ;
}

val dtree : t -> dtree option

val fold_dtree : (dtree -> 'a -> 'a) -> dtree -> 'a -> 'a
(** [fold_dtree f g z] applies [f] on each device in topological order. *)

val var_name : dtree -> string

val impl_name : dtree -> string

val explode :
  t ->
  [ `App of t * t list
  | `If of If.path value * (If.path * t) list
  | `Dev of a_device * [> `Args of t list ] * [> `Deps of t list ] ]
(** [explode g v] deconstructs the vertex [v] in the graph [g] into it's
    possible components. It also checks that the local invariants are respected. *)

val collect :
  (module Misc.Monoid with type t = 'ty) -> (label -> 'ty) -> t -> 'ty
(** [collect (module M) f g] collects the content of [f v] for each vertex [v]
    in [g]. *)

val hash : t -> int

val pp : t Fmt.t
(** Textual representation of the graph. *)

val pp_dot : t Fmt.t
(** Dot representation of the graph. *)
