(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Interface Lwt_util
 * Copyright (C) 2005-2008 Jérôme Vouillon
 * Laboratoire PPS - CNRS Université Paris Diderot
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

(** Note: This lodule is deprecated. Use {!Lwt_list} and {!Lwt_pool}
    instead. *)

(** {2 Lists iterators} *)

val iter : ('a -> unit Lwt.t) -> 'a list -> unit Lwt.t
    (** [iter f l] start a thread for each element in [l].  The threads
        are started according to the list order, but then can run
        concurrently.  It terminates when all the threads are
        terminated, if all threads are successful.  It fails if any of
        the threads fail. *)

val iter_serial : ('a -> unit Lwt.t) -> 'a list -> unit Lwt.t
    (** Similar to [iter] but wait for one thread to terminate before
        starting the next one. *)

val map : ('a -> 'b Lwt.t) -> 'a list -> 'b list Lwt.t
    (** [map f l] apply [f] to each element in [l] and collect the
        results of the threads thus created.  The threads are started
        according to the list order, but then can run concurrently.
        [map f l] fails if any of the threads fail. *)

val map_with_waiting_action :
    ('a -> 'b Lwt.t) -> ('a -> unit) -> 'a list -> 'b list Lwt.t
    (** [map_with_waiting_action f wa l] apply [f] to each element
        in [l] and collect the results of the threads thus created.
        The threads are started according to the list order, but
        then can run concurrently.  The difference with [map f l] is
        that function wa will be called on the element that the
        function is waiting for its termination.                     *)

val map_serial : ('a -> 'b Lwt.t) -> 'a list -> 'b list Lwt.t
    (** Similar to [map] but wait for one thread to terminate before
        starting the next one. *)

val fold_left : ('a -> 'b -> 'a Lwt.t) -> 'a -> 'b list -> 'a Lwt.t
    (** Similar to [List.fold_left]. *)

(****)

(** {2 Regions} *)

type region

val make_region : int -> region
      (** [make_region sz] create a region of size [sz]. *)
val resize_region : region -> int -> unit
      (** [resize_region reg sz] resize the region [reg] to size [sz]. *)
val run_in_region : region -> int -> (unit -> 'a Lwt.t) -> 'a Lwt.t
      (** [run_in_region reg size f] execute the thread produced by the
          function [f] in the region [reg]. The thread is not started
          before some room is available in the region. *)

(**/**)

val join : unit Lwt.t list -> unit Lwt.t
    (** Same as [Lwt.join] *)
