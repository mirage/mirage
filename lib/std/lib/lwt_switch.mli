(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Interface Lwt_switch
 * Copyright (C) 2010 Jérémiem Dimino
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

(** Lwt switches *)

(** Switch have two goals:

    - being able to free multiple resources at the same time,
    - offer a better alternative than always returning an id to free
      some resource.

    For example, considers the following interface:

    {[
      type id

      val free : id -> unit Lwt.t

      val f : unit -> id Lwt.t
      val g : unit -> id Lwt.t
      val h : unit -> id Lwt.t
    ]}

    Now you want to calls [f], [g] and [h] in parallel. You can
    simply do:

    {[
      lwt idf = f () and idg = g () and idh = h () in
      ...
    ]}

    However, one may wants to handle possible failures of [f ()], [g
    ()] and [h ()], and disable all allocated resources if one of
    these three threads fails. This may be hard since you have to
    remember which one failed and which one returned correctly.

    Now we change a little bit the interface:

    {[
      val f : ?switch : Lwt_switch.t -> unit -> id Lwt.t
      val g : ?switch : Lwt_switch.t -> unit -> id Lwt.t
      val h : ?switch : Lwt_switch.t -> unit -> id Lwt.t
    ]}

    and the code becomes:

    {[
      let switch = Lwt_switch.create () in
      try_lwt
        lwt idf = f ~switch () and idg = g ~switch () and idh = h ~switch () in
        ...
      with exn ->
        lwt () = Lwt_switch.turn_off switch in
        raise_lwt exn
    ]}
*)

type t
  (** Type of switches. *)

val create : unit -> t
  (** [create ()] creates a new switch. *)

val is_on : t -> bool
  (** [is_on switch] returns [true] if the switch is currently on, and
      [false] otherwise. *)

val turn_off : t -> unit Lwt.t
  (** [turn_off switch] turns off the switch. It calls all registered
      hooks, waits for all of them to terminates, and the returns. If
      one of the hook failed, then it will fail with one of the
      exception raised by hooks. If the switch is already off, then it
      does nothing. *)

exception Off
  (** Exception raised when trying to add a hook to a switch that is
      already off. *)

val check : t option -> unit
  (** [check switch] does nothing if [switch] is [None] or contains an
      switch that is currently on, and raise {!Off} otherwise. *)

val add_hook : t option -> (unit -> unit Lwt.t) -> unit
  (** [add_hook switch f] registers [f] so it will be called when
      {!turn_off} is invoked. It does nothing if [switch] is
      [None]. If [switch] contains an switch that is already off then
      {!Off} is raised. *)

val add_hook_or_exec : t option -> (unit -> unit Lwt.t) -> unit Lwt.t
  (** [add_hook_or_exec switch f] is the same as {!add_hook} except
      that if the switch is already off, then [f] is called
      immediatly. *)
