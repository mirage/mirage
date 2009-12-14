(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Interface Lwt_event
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

(** Events utilities *)

type notifier
  (** Type of event notifiers *)

val disable : notifier -> unit
  (** [disable notif] stops the corresponding event to be monitored *)

val notify : ('a -> unit) -> 'a React.event -> notifier
  (** [notify f ev] calls [f x] each time [ev] has a value [x] *)

val notify_p : ('a -> unit Lwt.t) -> 'a React.event -> notifier
  (** [notify_p f ev] is the same as [notify] except that [f x] is a
      thread. Calls to [f] are made in parallel. *)

val notify_s : ('a -> unit Lwt.t) -> 'a React.event -> notifier
  (** [notify_s f ev] is the same as [notify] except that [f x] is a
      thread. Calls to [f] are serialized. *)

val always_notify : ('a -> unit) -> 'a React.event -> unit
  (** Same as [notify] but does not return a notifier *)

val always_notify_p : ('a -> unit Lwt.t) -> 'a React.event -> unit
  (** Same as [notify_p] but does not return a notifier *)

val always_notify_s : ('a -> unit Lwt.t) -> 'a React.event -> unit
  (** Same as [notify_s] but does not return a notifier *)
