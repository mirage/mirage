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
open Printf

(* Global values for TCP parameters *)
let tcp_mss = 566
let tcp_wnd = tcp_mss * 4

type t = {
  mutable snd_una: Tcp_sequence.t;
  mutable snd_nxt: Tcp_sequence.t;
  mutable rcv_nxt: Tcp_sequence.t;
  mutable ack_last: Tcp_sequence.t; (* last sent ack number *)
  mutable snd_wnd: int;
  mutable rcv_closed: bool;
  mutable rcv_wnd: int;
  mutable ack_cnt: int;    (* input packets since last ack *)
  mutable ack_time: float; (* time last ack was sent *)
  ack: Tcp_sequence.t -> Tcp_sequence.t -> unit;
}

(* Initialise the sequence space *)
let t ~ack =
  (* XXX need random ISN *)
  let snd_nxt = Tcp_sequence.of_int32 7l in
  let snd_una = snd_nxt in
  let snd_wnd = tcp_wnd in (* XXX? *)
  let ack_last = Tcp_sequence.of_int32 0l in
  let rcv_nxt = Tcp_sequence.of_int32 0l in
  let rcv_wnd = 0 in
  let ack_cnt = 0 in
  let ack_time = 0. in
  let rcv_closed = false in
  { snd_una; snd_nxt; snd_wnd; rcv_nxt; rcv_wnd;
    ack_cnt; ack_last; ack_time; rcv_closed; ack }

(* Check if a sequence number is in the right range
   TODO: modulo 32 for wrap
 *)
let valid t seq =
  Tcp_sequence.between seq t.rcv_nxt (Tcp_sequence.of_int t.rcv_wnd)

(* Receive a SYN, so set sequence number *)
let rx_open ~rcv_wnd ~isn t =
  printf "TCP_window: rx_open wnd=%u ISN=%lu\n%!"
    rcv_wnd (Tcp_sequence.to_int32 isn);
  t.ack_last <- isn;
  t.rcv_wnd <- rcv_wnd;
  t.rcv_nxt <- Tcp_sequence.incr isn

(* Indicate a received FIN and advance the window by 1 *)
let rx_close t =
  if t.rcv_closed then 
    printf "TCP: warning, double rx FIN close\n%!"
  else begin
    t.rcv_closed <- true;
    t.rcv_nxt <- Tcp_sequence.incr t.rcv_nxt;
    printf "TCP: rx_close, seq=%lu\n%!" (Tcp_sequence.to_int32 t.rcv_nxt);
  end

(* Have we received a FIN from the other side? *)
let rx_closed t = t.rcv_closed

(* Advance received packet sequence number *)
let rx_advance t b =
  t.rcv_nxt <- Tcp_sequence.add t.rcv_nxt (Tcp_sequence.of_int b)

(* Notification that we have received a FIN *)
let rx_fin t =
  rx_advance t 1

(* Next expected receive sequence number *)
let rx_next t = t.rcv_nxt 
let rx_wnd t = t.rcv_wnd

(* transmit MSS of current connection *)
let tx_mss t =
  min t.snd_wnd tcp_wnd

(* Advance transmitted packet sequence number *)
let tx_advance t b =
  t.snd_nxt <- Tcp_sequence.add t.snd_nxt (Tcp_sequence.of_int b)

(* Notify the send window has been acknowledged *)
let tx_ack t ack_number =
  if Tcp_sequence.gt ack_number t.snd_una then begin
    let seq_l = t.snd_una in
    t.snd_una <- ack_number;
    printf "TCP: ACK, snd.una=%lu snd.nxt=%lu\n%!"
      (Tcp_sequence.to_int32 t.snd_una) (Tcp_sequence.to_int32 t.snd_nxt);
    (* Notify the ack listener *)
    t.ack seq_l ack_number;
  end

(* Notification that we have transmitted a FIN *)
let tx_fin t =
  tx_advance t 1

let tx_next t = t.snd_nxt 

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

(* See if an ack is needed on outgoing traffic *)
let ack_needed t =
  match (Tcp_sequence.lt t.ack_last t.rcv_nxt) with
  |true -> t.ack_cnt > 2 || (ack_timeout t)
  |false -> false
