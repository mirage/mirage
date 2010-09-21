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

external evtchn_nr_events: unit -> int = "caml_nr_events"
external evtchn_test_and_clear: int -> int = "caml_evtchn_test_and_clear"

type cb = 
  | Event_none
  | Event_direct of (unit -> unit)
  | Event_condition of unit Lwt_condition.t

let nr_events = evtchn_nr_events ()
let event_cb_rd = Array.create nr_events Event_none
let event_cb_wr = Array.create nr_events Event_none

(* Register an event channel port with a condition variable to let 
   threads sleep on it *)

let register_rd port cb = event_cb_rd.(port) <- cb
let register_wr port cb = event_cb_wr.(port) <- cb

let deregister port =
  event_cb_rd.(port) <- Event_none;
  event_cb_wr.(port) <- Event_none

(* Go through the event mask and activate any events, potentially spawning
   new threads *)

let run_cond = function
  | Event_none -> ()
  | Event_direct cb -> cb ()
  | Event_condition cond -> Lwt_condition.signal cond ()

let run () =
  for n = 1 to nr_events do
    let port = n - 1 in
    let evt = evtchn_test_and_clear port in
    if evt > 0 then begin
      let rd = evt land 1 = 1 in
      let wr = evt land 2 = 2 in
      let ex = evt land 4 = 4 in
      if rd || ex then run_cond event_cb_rd.(port);
      if wr || ex then run_cond event_cb_wr.(port)
    end
  done

