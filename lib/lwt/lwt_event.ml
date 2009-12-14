(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_event
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

type notifier = unit React.event Lwt_sequence.node

let notifiers = Lwt_sequence.create ()

let disable n =
  Lwt_sequence.remove n;
  React.E.stop (Lwt_sequence.get n)

let notify f event =
  Lwt_sequence.add_l (React.E.map f event) notifiers

let notify_p f event =
  Lwt_sequence.add_l (React.E.map (fun x -> Lwt.ignore_result (f x)) event) notifiers

let notify_s f event =
  let mutex = Lwt_mutex.create () in
  Lwt_sequence.add_l (React.E.map (fun x -> Lwt.ignore_result (Lwt_mutex.with_lock mutex (fun () -> f x))) event) notifiers

let always_notify f event =
  ignore (notify f event)

let always_notify_p f event =
  ignore (notify_p f event)

let always_notify_s f event =
  ignore (notify_s f event)
