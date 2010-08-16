(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

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
        end else acc
      in loop (n-1) acc
  in
  loop nr_events []
