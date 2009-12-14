(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Interface Lwt_timeout
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

type t

val set_exn_handler : (exn -> unit) -> unit
(** set the default handler for exception occurring after a timeout.
    The function lauched after a timeout should not raise any exception.
    That's why the default handler will exit the program.
*)

val create : int -> (unit -> unit) -> t
(** [create n f] defines a new timeout with [n] seconds duration. [f] is
    the function to be called after the timeout.
    That function must not raise any exception.
*)

val start : t -> unit
(** starts a timeout. *)

val stop : t -> unit
(** stops a timeout. *)

val change : t -> int -> unit
(** changes the duration of a timeout. *)
