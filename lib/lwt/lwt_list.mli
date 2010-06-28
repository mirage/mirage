(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Interface Lwt_list
 * Copyright (C) 2010 Jérémie Dimino
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

(** List helpers *)

(** Note: this module use the same naming convention as
    {!Lwt_stream}. *)

(** {6 List iterators} *)

val iter_s : ('a -> unit Lwt.t) -> 'a list -> unit Lwt.t
val iter_p : ('a -> unit Lwt.t) -> 'a list -> unit Lwt.t

val map_s : ('a -> 'b Lwt.t) -> 'a list -> 'b list Lwt.t
val map_p : ('a -> 'b Lwt.t) -> 'a list -> 'b list Lwt.t

val rev_map_s : ('a -> 'b Lwt.t) -> 'a list -> 'b list Lwt.t
val rev_map_p : ('a -> 'b Lwt.t) -> 'a list -> 'b list Lwt.t

val fold_left_s : ('a -> 'b -> 'a Lwt.t) -> 'a -> 'b list -> 'a Lwt.t

val fold_right_s : ('a -> 'b -> 'b Lwt.t) -> 'a list -> 'b -> 'b Lwt.t

(** {6 List scanning} *)

val for_all_s : ('a -> bool Lwt.t) -> 'a list -> bool Lwt.t
val for_all_p : ('a -> bool Lwt.t) -> 'a list -> bool Lwt.t

val exists_s : ('a -> bool Lwt.t) -> 'a list -> bool Lwt.t
val exists_p : ('a -> bool Lwt.t) -> 'a list -> bool Lwt.t

(** {6 List searching} *)

val find_s : ('a -> bool Lwt.t) -> 'a list -> 'a Lwt.t

val filter_s : ('a -> bool Lwt.t) -> 'a list -> 'a list Lwt.t
val filter_p : ('a -> bool Lwt.t) -> 'a list -> 'a list Lwt.t

val partition_s : ('a -> bool Lwt.t) -> 'a list -> ('a list * 'a list) Lwt.t
val partition_p : ('a -> bool Lwt.t) -> 'a list -> ('a list * 'a list) Lwt.t
