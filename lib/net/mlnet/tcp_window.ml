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

open Lwt

(* Global values for TCP parameters *)
let tcp_mss = 566
let tcp_wnd = tcp_mss * 4

type t = {
  mutable snd_una: int32;
  mutable snd_nxt: int32;
  mutable snd_wnd: int;
  mutable rcv_nxt: int32;
  mutable rcv_wnd: int;
  mutable count: int;
}

(* Initialise the sequence space *)
let t ~snd_isn ~rcv_wnd =
  (* XXX need random ISN *)
  let snd_una = 7l in
  let snd_nxt = snd_una in
  let snd_wnd = tcp_wnd in (* XXX? *)
  let rcv_nxt = Int32.succ snd_isn in
  let count = 0 in
  { snd_una; snd_nxt; snd_wnd; rcv_nxt; rcv_wnd; count }

(* Check if a sequence number is in the right range *)
let valid t (seq:int32) =
  (seq >= t.rcv_nxt) && (seq <= (Int32.add t.rcv_nxt (Int32.of_int t.rcv_wnd)))

let input t (tcp:Mpl.Tcp.o) =
  match tcp#data_length with
  | 0 ->
     (* no data, so no extra action required *)
     None
  | len ->
     let ack_number = Int32.(add t.rcv_nxt (of_int tcp#data_length)) in
     t.rcv_nxt <- ack_number;
     t.count <- t.count + 1;
     if t.count > 1 then (
       t.count <- 0;
       Some ack_number
     ) else
       None
