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

external evtchn_init: unit -> unit = "caml_evtchn_init"
external evtchn_nr_events: unit -> int = "caml_nr_events"
external evtchn_test_and_clear: int -> bool = "caml_evtchn_test_and_clear"

type cb =
  | Event_none
  | Event_direct of (unit -> unit)
  | Event_condition of unit Lwt_condition.t

let _ = evtchn_init ()
let nr_events = evtchn_nr_events ()
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
  for port = 0 to nr_events - 1 do
    if evtchn_test_and_clear port then begin
      match event_cb.(port) with
      | Event_none -> 
          Printf.printf "warning: event on port %d but no registered event\n%!" port
      | Event_direct cb ->
          cb (); 
      | Event_condition cond ->
          Lwt_condition.signal cond ();
    end
  done
