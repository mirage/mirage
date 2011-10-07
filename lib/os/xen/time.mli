(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_mirage, based on Lwt_unix
 * Copyright (C) 2010 Anil Madhavapeddy
 * Copyright (C) 2005-2008 Jerome Vouillon
 * Laboratoire PPS - CNRS Universite Paris Diderot
 *                    2009 Jeremie Dimino
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

val sleep : float -> unit Lwt.t
val yield : unit -> unit Lwt.t
val auto_yield : float -> unit -> unit Lwt.t
exception Timeout
val timeout : float -> 'a Lwt.t
val with_timeout : float -> (unit -> 'a Lwt.t) -> 'a Lwt.t
val restart_threads : float -> unit
val min_timeout : 'a option -> 'a option -> 'a option
val get_next_timeout : float -> float option -> float option
val process_timeouts : float -> float option
