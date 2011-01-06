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
  mutable snd_wnd: int;
  mutable rcv_closed: bool;
  mutable rcv_wnd: int;
  tx: Tcp_sequence.t -> Tcp_sequence.t -> unit;
  rx: Tcp_sequence.t -> unit;
}

(* Initialise the sequence space *)
let t ~tx ~rx =
  (* XXX need random ISN *)
  let snd_nxt = Tcp_sequence.of_int32 7l in
  let snd_una = snd_nxt in
  let snd_wnd = tcp_wnd in (* XXX? *)
  let rcv_nxt = Tcp_sequence.of_int32 0l in
  let rcv_wnd = 0 in
  let rcv_closed = false in
  { snd_una; snd_nxt; snd_wnd; rcv_nxt; rcv_wnd;
    rcv_closed; tx; rx }

(* Check if a sequence number is in the right range
   TODO: modulo 32 for wrap
 *)
let valid t seq =
  let redge = Tcp_sequence.(add t.rcv_nxt (of_int t.rcv_wnd)) in
  let r = Tcp_sequence.between seq t.rcv_nxt redge in
  printf "TCP_window: valid check for seq=%s for range %s[%d] res=%b\n%!"
    (Tcp_sequence.to_string seq) (Tcp_sequence.to_string t.rcv_nxt) t.rcv_wnd r;
  r

(* Receive a SYN, so set sequence number *)
let rx_open ~rcv_wnd ~isn t =
  printf "TCP_window: rx_open wnd=%u ISN=%lu\n%!"
    rcv_wnd (Tcp_sequence.to_int32 isn);
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
  printf "TCP_window: advancing window by %d\n%!" b;
  t.rcv_nxt <- Tcp_sequence.add t.rcv_nxt (Tcp_sequence.of_int b);
  t.rx t.rcv_nxt

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
    t.tx seq_l ack_number;
  end

(* Notification that we have transmitted a FIN *)
let tx_fin t =
  tx_advance t 1

let tx_next t = t.snd_nxt 

let tx_wnd t = t.snd_wnd
