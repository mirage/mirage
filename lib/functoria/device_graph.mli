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

(* val create : _ impl -> t
 * (\** [create impl] creates a graph based [impl]. *\) *)

(* val normalize : t -> t
 * (\** [normalize g] normalize the graph [g] by removing the [App] vertices. *\) *)

(* val eval : ?partial:bool -> context:context -> t -> t
 * (\** [eval ~keys g] will removes all the [If] vertices by resolving the keys
 *     using [keys]. It will then call {!normalize}
 * 
 *     If [partial] is [true], then it will only evaluate [If] vertices which
 *     condition is resolved. *\) *)


(* (\** Collections *\)
 * 
 * (\** The description of a vertex *\)
 * type label = If : _ Key.value -> label | Dev : _ Device.t -> label | App
 * 
 * val collect :
 *   (module Misc.Monoid with type t = 'ty) -> (label -> 'ty) -> t -> 'ty
 * (\** [collect (module M) f g] collects the content of [f v] for each vertex [v]
 *     in [g]. *\)
 * 
 * (\** Evaluated device trees *\) *)

type t = D : {
  dev : _ Device.t ;
  args : t list ;
  deps : t list ;
  id : int ;
} -> t

(* val dtree : t -> dtree option *)

val fold_dtree : (t -> 'a -> 'a) -> t -> 'a -> 'a
(** [fold_dtree f g z] applies [f] on each device in topological order. *)

val var_name : t -> string

val impl_name : t -> string
