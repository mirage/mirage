(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Interface Lwt_mutex
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

(** Cooperative locks for mutual exclusion *)

type t
  (** Type of Lwt mutexes *)

val create : unit -> t
  (** [create ()] creates a new mutex, which is initially unlocked *)

val lock : t -> unit Lwt.t
  (** [lock mutex] lockcs the mutex, that is:

      - if the mutex is unlocked, then it is marked as locked and
        {!lock} returns immediatly

      - if it is locked, then {!lock} waits for all threads waiting on
        the mutex to terminate, then it resumes when the last one
        unlocks the mutex

      Note: threads are wake up is the same order they try to lock the
      mutex *)

val unlock : t -> unit
  (** [unlock mutex] unlock the mutex if no threads is waiting on
      it. Otherwise it will eventually removes the first one and
      resumes it. *)

val is_locked : t -> bool
  (** [locked mutex] returns whether [mutex] is currently locked *)

val is_empty : t -> bool
  (** [is_empty mutex] returns [true] if they are no thread waiting on
      the mutex, and [false] otherwise *)

val with_lock : t -> (unit -> 'a Lwt.t) -> 'a Lwt.t
  (** [with_lock lock f] is used to lock a mutex within a block scope.
      The function [f ()] is called with the mutex locked, and its
      result is returned from the call to {with_lock}. If an exception
      is raised from f, the mutex is also unlocked before the scope of
      {with_lock} is exited. *)
