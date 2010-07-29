(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_main
 * Copyright (C) 2009 Jérémie Dimino
 * Copyright (C) 2010 Anil Madhavapeddy <anil@recoil.org>
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

type current_time = float Lazy.t
type select = float option -> current_time

external block_domain : float -> unit = "mirage_block_domain"

module Activations = struct

    open Bigarray

    external evtchn_init : unit -> (int, int8_unsigned_elt, c_layout) Array1.t = "caml_evtchn_init"
    let event_mask = evtchn_init ()
    let nr_events = Array1.dim event_mask

    type cb = 
      | Event_none
      | Event_direct of (unit -> unit)
      | Event_thread of (unit -> unit Lwt.t)

    let event_cb = Array.create nr_events Event_none

    (* Register an event channel port with a condition variable to let 
       threads sleep on it *)
    let register port cb =
       if event_cb.(port) != Event_none then
           Printf.printf "warning: port %d already registered\n%!" port
       else
           Printf.printf "notice: registering port %d\n%!" port;
       event_cb.(port) <- cb

    (* Go through the event mask and activate any events, potentially spawning
       new threads *)
    let run () =
       let rec loop n acc =
         match n with
         | 0 -> acc
         | n -> 
             let port = n - 1 in
             let acc = 
               if Array1.get event_mask port = 1 then begin
                 match event_cb.(port) with
                 | Event_none -> 
                      Printf.printf "warning: event on port %d but no registered event\n%!" port;
                      acc
                 | Event_direct cb ->
                      Array1.set event_mask port 0;
                      cb (); 
                      acc
                 | Event_thread cb ->
                      Array1.set event_mask port 0;
                      cb () :: acc
               end 
                 else acc
             in loop (n-1) acc
       in
       loop nr_events []
       
end

let select_filters = Lwt_sequence.create ()

let min_timeout a b = match a, b with
  | None, b -> b
  | a, None -> a
  | Some a, Some b -> Some(min a b)

let apply_filters select =
  let now = Lazy.lazy_from_fun Mir.gettimeofday in
  Lwt_sequence.fold_l (fun filter select -> filter now select) select_filters select

let default_select timeout =
  block_domain (match timeout with None -> 10. |Some t -> t);
  let activations = Activations.run () in
  Lazy.lazy_from_fun Mir.gettimeofday, activations

let default_iteration () =
  Lwt.wakeup_paused ();
  apply_filters default_select None

let rec run t =
  Lwt.wakeup_paused ();
  match Lwt.poll t with
    | Some x ->
        x
    | None ->
        let _, activations = default_iteration () in
        run (join (t :: activations))

let exit_hooks = Lwt_sequence.create ()

let rec call_hooks () =
  match Lwt_sequence.take_opt_l exit_hooks with
    | None ->
        return ()
    | Some f ->
        lwt () =
          try_lwt
            f ()
          with exn ->
            return ()
        in
        call_hooks ()

let () = at_exit (fun () -> run (call_hooks ()))
let at_exit f = ignore (Lwt_sequence.add_l f exit_hooks)
