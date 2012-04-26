(*
 * Copyright (c) 2012 Balraj Singh <bs375@cl.cam.ac.uk>
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

open Lwt
open Printf

type action =
  | Passive_open
  | Recv_rst
  | Recv_synack of Sequence.t
  | Recv_ack of Sequence.t
  | Recv_fin
  | Recv_finack of Sequence.t
  | Send_syn of Sequence.t
  | Send_synack of Sequence.t
  | Send_rst
  | Send_fin of Sequence.t
  | Timeout

type tcpstates = 
  | Closed
  | Listen
  | Syn_rcvd of Sequence.t
  | Syn_sent of Sequence.t
  | Established
  | Close_wait
  | Last_ack of Sequence.t
  | Fin_wait_1 of Sequence.t
  | Fin_wait_2 of int
  | Closing of Sequence.t
  | Time_wait

type close_cb = unit -> unit

type t = {
  on_close: close_cb;  
  mutable state: tcpstates;
}

exception Bad_transition of (tcpstates * action)

let t ~on_close =
  { on_close; state=Closed }

let state t = t.state

let action_to_string = function
  | Passive_open -> "Passive_open"
  | Recv_rst -> "Recv_rst"
  | Recv_synack x -> "Recv_synack " ^ (Sequence.to_string x)
  | Recv_ack x -> "Recv_ack " ^ (Sequence.to_string x)
  | Recv_fin -> "Recv_fin"
  | Recv_finack x -> "Recv_finack " ^ (Sequence.to_string x)
  | Send_syn x -> "Send_syn " ^ (Sequence.to_string x)
  | Send_synack x -> "Send_synack " ^ (Sequence.to_string x)
  | Send_rst -> "Send_rst"
  | Send_fin x -> "Send_fin " ^ (Sequence.to_string x)
  | Timeout -> "Timeout"

let tcpstates_to_string = function
  | Closed -> "Closed"
  | Listen -> "Listen"
  | Syn_rcvd x -> "Syn_rcvd " ^ (Sequence.to_string x)
  | Syn_sent x -> "Syn_sent " ^ (Sequence.to_string x)
  | Established -> "Established"
  | Close_wait -> "Close_wait"
  | Last_ack x -> "Last_ack " ^ (Sequence.to_string x)
  | Fin_wait_1 x -> "Fin_wait_1 " ^ (Sequence.to_string x)
  | Fin_wait_2 i -> "Fin_wait_2 " ^ (string_of_int i)
  | Closing x -> "Closing " ^ (Sequence.to_string x)
  | Time_wait -> "Time_wait"

let to_string t =
  sprintf "{ %s }" (tcpstates_to_string t.state)

let rec finwait2timer t count timeout =
  OS.Time.sleep timeout >>
  match t.state with
  | Fin_wait_2 i ->
      if i = count then begin
	t.state <- Closed;
	t.on_close ();
	return ()
      end else begin
	finwait2timer t i timeout
      end
  | _ ->
      return ()
  

let timewait t twomsl =
  OS.Time.sleep twomsl >>
  (t.state <- Closed;
   t.on_close ();
   return ())


let tick t (i:action) =
  (* printf "%s  - %s ->  " (to_string t) (action_to_string i); *)
  let diffone x y = Sequence.incr y = x in
  let tstr s (i:action) =
    match s, i with
    | Closed, Passive_open -> Listen
    | Closed, Send_syn a -> Syn_sent a
    | Listen, Send_synack a -> Syn_rcvd a
    | Syn_rcvd a, Timeout -> t.on_close (); Closed
    | Syn_rcvd a, Recv_rst -> t.on_close (); Closed
    | Syn_sent a, Timeout -> t.on_close (); Closed
    | Syn_sent a, Recv_synack b-> if diffone b a then Established else Syn_sent a
    | Syn_rcvd a, Recv_ack b -> if diffone b a then Established else Syn_rcvd a
    | Established, Recv_ack a -> Established
    | Established, Send_fin a -> Fin_wait_1 a
    | Established, Recv_fin -> Close_wait
    | Established, Timeout -> t.on_close (); Closed
    | Fin_wait_1 a, Recv_ack b ->
	if diffone b a then
	  let count = 0 in
	  let _ = finwait2timer t count 60. in
	  Fin_wait_2 count
        else
	  Fin_wait_1 a
    | Fin_wait_1 a, Recv_fin -> Closing a
    | Fin_wait_1 a, Recv_finack b -> if diffone b a then Time_wait else Fin_wait_1 a
    | Fin_wait_1 a, Timeout -> t.on_close (); Closed
    | Fin_wait_2 i, Recv_ack _ -> Fin_wait_2 (i + 1)
    | Fin_wait_2 i, Recv_fin -> let _ = timewait t 30. in Time_wait
    | Closing a, Recv_ack b -> if diffone b a then Time_wait else Closing a
    | Time_wait, Timeout -> t.on_close (); Closed
    | Close_wait,  Send_fin a -> Last_ack a
    | Close_wait,  Timeout -> t.on_close (); Closed
    | Last_ack a, Recv_ack b -> if diffone b a then (t.on_close (); Closed) else Last_ack a
    | Last_ack a, Timeout -> t.on_close (); Closed
    | x, _ -> x
  in
  t.state <- tstr t.state i
  (* ;  printf "%s\n%!" (to_string t) *)

