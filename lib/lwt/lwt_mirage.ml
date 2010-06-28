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

type sleep = {
  time : float;
  mutable canceled : bool;
  thread : unit Lwt.u;
}

module SleepQueue =
  Lwt_pqueue.Make (struct
                     type t = sleep
                     let compare { time = t1 } { time = t2 } = compare t1 t2
                   end)

(* Threads waiting for a timeout to expire: *)
let sleep_queue = ref SleepQueue.empty

(* Sleepers added since the last iteration of the main loop:

   They are not added immediatly to the main sleep queue in order to
   prevent them from being wakeup immediatly by [restart_threads].
*)
let new_sleeps = ref []

let sleep d =
  let (res, w) = Lwt.task () in
  let t = if d <= 0. then 0. else Mir.gettimeofday () +. d in
  let sleeper = { time = t; canceled = false; thread = w } in
  new_sleeps := sleeper :: !new_sleeps;
  Lwt.on_cancel res (fun _ -> sleeper.canceled <- true);
  res

let yield () = sleep 0.

let auto_yield timeout =
  let limit = ref (Mir.gettimeofday () +. timeout) in
  fun () ->
    let current = Mir.gettimeofday () in
    if current >= !limit then begin
      limit := current +. timeout;
      yield ();
    end else
      return ()

exception Timeout

let timeout d = sleep d >> Lwt.fail Timeout

let with_timeout d f = Lwt.pick [timeout d; Lwt.apply f ()]

let in_the_past now t =
  t = 0. || t <= Lazy.force now

(* We use a lazy-value for [now] to avoid one system call if not
   needed: *)
let rec restart_threads now =
  match SleepQueue.lookup_min !sleep_queue with
    | Some{ canceled = true } ->
        sleep_queue := SleepQueue.remove_min !sleep_queue;
        restart_threads now
    | Some{ time = time; thread = thread } when in_the_past now time ->
        sleep_queue := SleepQueue.remove_min !sleep_queue;
        Lwt.wakeup thread ();
        restart_threads now
    | _ ->
        ()

(* +-----------------------------------------------------------------+
   | Mirage descriptors                                              |
   +-----------------------------------------------------------------+ *)

(* XXX TODO fill in *)
let inputs = ref [ [()] ]
let outputs = ref [ [()] ]
let active_descriptors set acc = []
let perform_actions set fd = ()
   
(* +-----------------------------------------------------------------+
   | Event loop                                                      |
   +-----------------------------------------------------------------+ *)

let run = Lwt_mirage_main.run

let rec get_next_timeout now timeout =
  match SleepQueue.lookup_min !sleep_queue with
    | Some{ canceled = true } ->
        sleep_queue := SleepQueue.remove_min !sleep_queue;
        get_next_timeout now timeout
    | Some{ time = time } ->
        Lwt_mirage_main.min_timeout timeout (Some(if time = 0. then 0. else max 0. (time -. (Lazy.force now))))
    | None ->
        timeout

let select_filter now select set_r set_w set_e timeout =
  (* Transfer all sleepers added since the last iteration to the main
     sleep queue: *)
  sleep_queue :=
    List.fold_left
      (fun q e -> SleepQueue.add e q) !sleep_queue !new_sleeps;
  new_sleeps := [];
  let (now, set_r, set_w, set_e) as result =
    select
      (active_descriptors inputs set_r)
      (active_descriptors outputs set_w)
      set_e
      (get_next_timeout now timeout)
  in
  (* Restart threads waiting for a timeout: *)
  restart_threads now;
  (* Restart threads waiting on a file descriptors: *)
  List.iter (fun fd -> perform_actions inputs fd) set_r;
  List.iter (fun fd -> perform_actions outputs fd) set_w;
  result

let _ = Lwt_sequence.add_l select_filter Lwt_mirage_main.select_filters

