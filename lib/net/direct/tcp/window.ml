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

type t = {
  tx_mss: int;
  mutable snd_una: Sequence.t;
  mutable tx_nxt: Sequence.t;
  mutable rx_nxt: Sequence.t;
  mutable tx_wnd: int32;           (* TX Window size after scaling *)
  mutable rx_wnd: int32;           (* RX Window size after scaling *)
  mutable tx_wnd_scale: int;       (* TX Window scaling option     *)
  mutable rx_wnd_scale: int;       (* RX Window scaling option     *)
}

let default_mss = 536

(* To string for debugging *)
let to_string t =
  sprintf "rx_nxt=%s tx_nxt=%s rx_wnd=%lu tx_wnd=%lu snd_una=%s"
    (Sequence.to_string t.rx_nxt) (Sequence.to_string t.tx_nxt)
    t.rx_wnd t.tx_wnd (Sequence.to_string t.snd_una)

(* Initialise the sequence space *)
let t ~rx_wnd_scale ~tx_wnd_scale ~rx_wnd ~tx_wnd ~rx_isn ~tx_mss =
  (* XXX need random ISN XXX *)
  let tx_nxt = Sequence.of_int32 7l in
  let rx_nxt = Sequence.(incr rx_isn) in
  let tx_mss = match tx_mss with |None -> default_mss |Some mss -> mss in
  let snd_una = tx_nxt in
  let rx_wnd = Int32.(shift_left (of_int rx_wnd) rx_wnd_scale) in
  let tx_wnd = Int32.(shift_left (of_int tx_wnd) tx_wnd_scale) in
  { snd_una; tx_nxt; tx_wnd; rx_nxt; rx_wnd; tx_wnd_scale; rx_wnd_scale; tx_mss }

(* Check if a sequence number is in the right range
   TODO: modulo 32 for wrap
 *)
let valid t seq =
  let redge = Sequence.(add t.rx_nxt (of_int32 t.rx_wnd)) in
  let r = Sequence.between seq t.rx_nxt redge in
  printf "TCP_window: valid check for seq=%s for range %s[%lu] res=%b\n%!"
    (Sequence.to_string seq) (Sequence.to_string t.rx_nxt) t.rx_wnd r;
  r

(* Advance received packet sequence number *)
let rx_advance t b =
  t.rx_nxt <- Sequence.add t.rx_nxt (Sequence.of_int b)

(* Next expected receive sequence number *)
let rx_nxt t = t.rx_nxt 
let rx_wnd t = t.rx_wnd

(* TODO: scale the window down so we can advertise it correctly with
   window scaling on the wire *)
let set_rx_wnd t sz =
  t.rx_wnd <- sz

(* Take an unscaled value and scale it up *)
let set_tx_wnd t sz =
  let wnd = Int32.(shift_left (of_int sz) t.tx_wnd_scale) in
  t.tx_wnd <- wnd

(* transmit MSS of current connection *)
let tx_mss t =
  t.tx_mss

(* Advance transmitted packet sequence number *)
let tx_advance t b =
  t.tx_nxt <- Sequence.add t.tx_nxt (Sequence.of_int b)

(* Notify the send window has been acknowledged *)
let tx_ack t r =
  if Sequence.gt r t.snd_una then begin
    t.snd_una <- r;
  end

let tx_nxt t = t.tx_nxt 
let tx_wnd t = t.tx_wnd
let tx_una t = t.snd_una
