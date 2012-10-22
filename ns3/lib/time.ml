(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_mirage, based on Lwt_unix
 * Copyright (C) 2010 Anil Madhavapeddy
 * Copyright (C) 2005-2008 Jérôme Vouillon
 * Laboratoire PPS - CNRS Université Paris Diderot
 *                    2009 Jérémie Dimino
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

open Lwt

(* +-----------------------------------------------------------------+
   | Sleepers                                                        |
   +-----------------------------------------------------------------+ *)

external ns3_add_timer_event : float -> int -> unit = "ocaml_ns3_add_timer_event"

type sleep = {
  time : float;
  id : int;
  mutable canceled : bool;
  thread : unit Lwt.u;
}

let count = ref 0
let sleeping_threads = (Hashtbl.create 64)

let sleep d =
  let (res, w) = Lwt.task () in
  let t = if d <= 0. then 0. else Clock.time () +. d in
  let id = (!count) in
  count := (!count) + 1;
  let sleeper = { time = t; canceled = false; thread = w; id; } in 
  Hashtbl.replace sleeping_threads id sleeper;
  ns3_add_timer_event d id;
  Lwt.on_cancel res (fun _ -> sleeper.canceled <- true);
  res

let yield () = sleep 0.

let auto_yield timeout =
  let limit = ref (Clock.time () +. timeout) in
  fun () ->
    let current = Clock.time () in
    if current >= !limit then begin
      limit := current +. timeout;
      yield ();
    end else
      return ()

exception Timeout

let timeout d = sleep d >> Lwt.fail Timeout

let with_timeout d f = Lwt.pick [timeout d; Lwt.apply f ()]

let wakeup_thread id =
  let thread = Hashtbl.find sleeping_threads id in 
  let _ = 
    match thread with 
      |  { canceled = true } -> 
          Hashtbl.remove sleeping_threads id
      |  { thread = thread } -> 
          Lwt.wakeup thread ();
          Hashtbl.remove sleeping_threads id
  in
  let _= Lwt.wakeup_all () in
    () 

let _ = Callback.register "timer_wakeup" wakeup_thread

let duration = ref 0
let set_duration secs = 
  duration := secs
let get_duration () =
  !duration

let rec restart_threads now = ()
let select_next now = None
