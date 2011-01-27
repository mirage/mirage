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
let tcp_wnd = Int32.of_int (tcp_mss * 4)

type t = {
  mutable snd_una: Tcp_sequence.t;
  mutable tx_nxt: Tcp_sequence.t;
  mutable rx_nxt: Tcp_sequence.t;
  mutable tx_wnd: int32;  (* TX Window size after scaling *)
  mutable rx_wnd: int32;  (* RX Window size after scaling *)
  mutable tx_wnd_scale: int;  (* TX Window scaling option *)
  mutable rx_wnd_scale: int;  (* RX Window scaling option *)
}

(* Initialise the sequence space *)
let t ~rx_wnd_scale ~tx_wnd_scale ~rx_wnd ~rx_isn =
  (* XXX need random ISN *)
  let tx_nxt = Tcp_sequence.of_int32 7l in
  let rx_nxt = Tcp_sequence.(incr rx_isn) in
  let snd_una = tx_nxt in
  let tx_wnd = Int32.shift_left tcp_wnd tx_wnd_scale in (* TODO: tx window size *)
  let rx_wnd = Int32.(shift_left (of_int rx_wnd) rx_wnd_scale) in
  { snd_una; tx_nxt; tx_wnd; rx_nxt; rx_wnd; tx_wnd_scale; rx_wnd_scale }

(* Check if a sequence number is in the right range
   TODO: modulo 32 for wrap
 *)
let valid t seq =
  let redge = Tcp_sequence.(add t.rx_nxt (of_int32 t.rx_wnd)) in
  let r = Tcp_sequence.between seq t.rx_nxt redge in
  printf "TCP_window: valid check for seq=%s for range %s[%lu] res=%b\n%!"
    (Tcp_sequence.to_string seq) (Tcp_sequence.to_string t.rx_nxt) t.rx_wnd r;
  r

(* Advance received packet sequence number *)
let rx_advance t b =
  t.rx_nxt <- Tcp_sequence.add t.rx_nxt (Tcp_sequence.of_int b)

(* Next expected receive sequence number *)
let rx_nxt t = t.rx_nxt 
let rx_wnd t = t.rx_wnd
let set_rx_wnd t sz = t.rx_wnd <- sz

(* transmit MSS of current connection *)
let tx_mss t =
  min t.tx_wnd tcp_wnd

(* Advance transmitted packet sequence number *)
let tx_advance t b =
  t.tx_nxt <- Tcp_sequence.add t.tx_nxt (Tcp_sequence.of_int b)

(* Notify the send window has been acknowledged *)
let tx_ack t r =
  if Tcp_sequence.gt r t.snd_una then begin
    t.snd_una <- r;
    printf "TCP: ACK, snd.una=%lu snd.nxt=%lu\n%!"
      (Tcp_sequence.to_int32 t.snd_una) (Tcp_sequence.to_int32 t.tx_nxt);
  end

let tx_nxt t = t.tx_nxt 
let tx_wnd t = t.tx_wnd
let tx_una t = t.snd_una
