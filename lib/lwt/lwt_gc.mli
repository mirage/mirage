(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_gc
 * Copyright (C) 2009 Jérémie Dimino
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

(** Interaction with the garbage collector *)

(** This module offer a convenient way to add a finaliser launching a
    thread to a value, without having to use [Lwt_unix.run] in the
    finaliser. *)

val finalise : ('a -> unit Lwt.t) -> 'a -> unit
  (** [finalise f x] calls [f x] when [x] is garbage collected. If [f
      x] yields, then Lwt will waits for its termination at the end of
      the program. *)

val finalise_or_exit : ('a -> unit Lwt.t) -> 'a -> unit
  (** [finalise_or_exit f x] call [f x] when [x] is garbage collected
      or (exclusively) when the program exit. *)
