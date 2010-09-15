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

external evtchn_init : unit -> int array = "caml_evtchn_init"
let event_mask = evtchn_init ()
let nr_events = Array.length event_mask

type cb = 
  | Event_none
  | Event_direct of (unit -> unit)
  | Event_condition of unit Lwt_condition.t

let event_cb = Array.create nr_events Event_none

(* Register an event channel port with a condition variable to let 
   threads sleep on it *)
let register port cb =
  if event_cb.(port) != Event_none then
    Console.printf "warning: port %d already registered\n%!" port
  else
    Console.printf "notice: registering port %d\n%!" port;
  event_cb.(port) <- cb

(* Go through the event mask and activate any events *)
let run () =
  for n = 1 to nr_events do
    let port = n - 1 in
    if event_mask.(port) = 1 then begin
      match event_cb.(port) with
        | Event_none -> 
            Console.printf "warning: event on port %d but no registered event\n%!" port
        | Event_direct cb ->
            event_mask.(port) <- 0;
            cb ();
        | Event_condition cond ->
					  (* Console.printf "[activation] Event_condition on port %i" port; *)
            event_mask.(port) <- 0;
            Lwt_condition.signal cond ()
    end
  done

