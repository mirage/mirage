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
  mutable ack_cnt: int;    (* input packets since last ack *)
  mutable ack_last: int32; (* last sent ack number *)
  mutable ack_time: float; (* time last ack was sent *)
}

(* Initialise the sequence space *)
let t ~snd_isn ~rcv_wnd =
  (* XXX need random ISN *)
  let snd_una = 7l in
  let snd_nxt = snd_una in
  let snd_wnd = tcp_wnd in (* XXX? *)
  let rcv_nxt = Int32.succ snd_isn in
  let ack_cnt = 0 in
  let ack_last = Int32.sub rcv_nxt 1l in
  let ack_time = OS.Clock.time () in
  { snd_una; snd_nxt; snd_wnd; rcv_nxt; rcv_wnd;
    ack_cnt; ack_last; ack_time }

(* Check if a sequence number is in the right range
   TODO: modulo 32 for wrap
 *)
let valid t (seq:int32) =
  (seq >= t.rcv_nxt) &&
  (seq <= (Int32.add t.rcv_nxt (Int32.of_int t.rcv_wnd)))

(* Advance received packet sequence number *)
let rx_advance t b =
  t.rcv_nxt <- Int32.add t.rcv_nxt (Int32.of_int b)

(* Advance transmitted packet sequence number *)
let tx_advance t b =
  t.snd_nxt <- Int32.add t.snd_nxt (Int32.of_int b)

let ack_send t =
  t.ack_cnt <- 0;
  t.ack_last <- t.rcv_nxt

let ack_timeout t =
  let x = OS.Clock.time () -. t.ack_time in
  x > 0.03

(* Crank up the ack counter so we force an immediate
   ACK from the transmit queue *)
let ack_immediate t =
  t.ack_cnt <- 100

(* Notification that we have transmitted a FIN *)
let tx_fin t =
  tx_advance t 1

(* Notification that we have received a FIN *)
let rx_fin t =
  rx_advance t 1;
  ack_immediate t

(* Next expected receive sequence number *)
let rx_next t = t.rcv_nxt 
let rx_wnd t = t.rcv_wnd
let tx_next t = t.snd_nxt 

(* transmit MSS of current connection *)
let tx_mss t =
  min t.snd_wnd tcp_wnd

(* See if an ack is needed on outgoing traffic *)
let ack_needed t =
  match (t.ack_last < t.rcv_nxt) with
  |true -> t.ack_cnt > 2 || (ack_timeout t)
  |false -> false
