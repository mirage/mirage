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
  tx_isn: Sequence.t;
  rx_isn: Sequence.t;
  max_rx_wnd: int32;               (* Max RX Window size after scaling *)
  tx_wnd_scale: int;               (* TX Window scaling option     *)
  rx_wnd_scale: int;               (* RX Window scaling option     *)
  mutable snd_una: Sequence.t;
  mutable tx_nxt: Sequence.t;
  mutable rx_nxt: Sequence.t;
  mutable rx_nxt_inseq: Sequence.t;
  mutable tx_wnd: int32;           (* TX Window size after scaling *)
  mutable rx_wnd: int32;           (* RX Window size after scaling *)
  mutable ssthresh: int32;         (* threshold to switch from exponential
				      slow start to linear congestion
				      avoidance
				    *)
  mutable cwnd: int32;             (* congestion window *)
  mutable fast_recovery: bool;     (* flag to mark if this tcp is in
				      fast recovery *)

  mutable rtt_timer_on: bool;
  mutable rtt_timer_reset: bool;
  mutable rtt_timer_seq: Sequence.t;
  mutable rtt_timer_starttime: float;
  mutable srtt: float;
  mutable rttvar: float;
  mutable rto: float;
  mutable backoff_count: int;
}

let default_mss = 536
let max_mss = 1460

let alpha = 0.125  (* see RFC 2988 *)
let beta = 0.25    (* see RFC 2988 *)

(* To string for debugging *)
let to_string t =
  sprintf "rx_nxt=%s rx_nxt_inseq=%s tx_nxt=%s rx_wnd=%lu tx_wnd=%lu snd_una=%s"
    (Sequence.to_string t.rx_nxt)
    (Sequence.to_string t.rx_nxt_inseq)
    (Sequence.to_string t.tx_nxt)
    t.rx_wnd t.tx_wnd (Sequence.to_string t.snd_una)

(* Initialise the sequence space *)
let t ~rx_wnd_scale ~tx_wnd_scale ~rx_wnd ~tx_wnd ~rx_isn ~tx_mss ~tx_isn =
  let tx_nxt = tx_isn in
  let rx_nxt = Sequence.(incr rx_isn) in
  let rx_nxt_inseq = Sequence.(incr rx_isn) in
  (* TODO: improve this sanity check of tx_mss *)
  let tx_mss = match tx_mss with |None -> default_mss |Some mss -> min mss max_mss in
  let snd_una = tx_nxt in
  let rx_wnd = Int32.(shift_left (of_int rx_wnd) rx_wnd_scale) in
  let max_rx_wnd = rx_wnd in
  let tx_wnd = Int32.(shift_left (of_int tx_wnd) tx_wnd_scale) in
  (* ssthresh is initialized per RFC 2581 to a large value so slow-start
     can be used all the way till first loss *)
  let ssthresh = tx_wnd in
  let cwnd = Int32.of_int (tx_mss * 2) in
  let fast_recovery = false in
  let rtt_timer_on = false in
  let rtt_timer_reset = true in
  let rtt_timer_seq = tx_nxt in
  let rtt_timer_starttime = 0.0 in
  let srtt = 1.0 in
  let rttvar = 0.0 in
  let rto = 3.0 in
  let backoff_count = 0 in
  { tx_isn; rx_isn; max_rx_wnd; snd_una; tx_nxt; tx_wnd; rx_nxt; rx_nxt_inseq;
    rx_wnd; tx_wnd_scale; rx_wnd_scale;
    ssthresh; cwnd; tx_mss; fast_recovery;
    rtt_timer_on; rtt_timer_reset;
    rtt_timer_seq; rtt_timer_starttime; srtt; rttvar; rto; backoff_count }

(* Check if a sequence number is in the right range
   TODO: modulo 32 for wrap
 *)
let valid t seq =
  let redge = Sequence.(add t.rx_nxt (of_int32 t.rx_wnd)) in
  let ledge = Sequence.(sub t.rx_nxt (of_int32 t.max_rx_wnd)) in 
  let r = Sequence.between seq ledge redge in
  (* printf "TCP_window: valid check for seq=%s for range %s[%lu] res=%b\n%!"
    (Sequence.to_string seq) (Sequence.to_string t.rx_nxt) t.rx_wnd r; *)
  r

(* Advance received packet sequence number *)
let rx_advance t b =
  t.rx_nxt <- Sequence.add t.rx_nxt (Sequence.of_int b)

(* Early advance received packet sequence number for packet ordering *)
let rx_advance_inseq t b =
  t.rx_nxt_inseq <- Sequence.add t.rx_nxt_inseq (Sequence.of_int b)

(* Next expected receive sequence number *)
let rx_nxt t = t.rx_nxt 
let rx_nxt_inseq t = t.rx_nxt_inseq
let rx_wnd t = t.rx_wnd
let rx_wnd_unscaled t = Int32.shift_right t.rx_wnd t.rx_wnd_scale

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
  if not t.rtt_timer_on && not t.fast_recovery then begin
    t.rtt_timer_on <- true;
    t.rtt_timer_seq <- t.tx_nxt;
    t.rtt_timer_starttime <- OS.Clock.time ();
  end;
  t.tx_nxt <- Sequence.add t.tx_nxt (Sequence.of_int b)

(* An ACK was received - use it to adjust cwnd *)
let tx_ack t r win =
  set_tx_wnd t win;
  if t.fast_recovery then begin
    if Sequence.gt r t.snd_una then begin
      (* printf "EXITING fast recovery\n%!"; *)
      t.snd_una <- r;
      t.cwnd <- t.ssthresh;
      t.fast_recovery <- false;
    end else begin
      t.cwnd <- (Int32.add t.cwnd (Int32.of_int t.tx_mss));
    end
  end else begin
    if Sequence.gt r t.snd_una then begin
      t.backoff_count <- 0;
      t.snd_una <- r;
      if t.rtt_timer_on && Sequence.gt r t.rtt_timer_seq then begin
        t.rtt_timer_on <- false;
        let rtt_m = OS.Clock.time () -. t.rtt_timer_starttime in
	if t.rtt_timer_reset then begin
	  t.rtt_timer_reset <- false;
          t.rttvar <- (0.5 *. rtt_m);
          t.srtt <- rtt_m;
	end else begin
          t.rttvar <- (((1.0 -. beta) *. t.rttvar) +. (beta *. (abs_float (t.srtt -. rtt_m))));
          t.srtt <- (((1.0 -. alpha) *. t.srtt) +. (alpha *. rtt_m));
	end;
        t.rto <- (max 1.0 (t.srtt +. (4.0 *. t.rttvar)));
      end;
    end;
    let cwnd_incr = match t.cwnd < t.ssthresh with
    | true -> Int32.of_int t.tx_mss
    | false -> max (Int32.div (Int32.of_int (t.tx_mss * t.tx_mss)) t.cwnd) 1l
    in
    t.cwnd <- Int32.add t.cwnd cwnd_incr
  end

let tx_nxt t = t.tx_nxt 
let tx_wnd t = t.tx_wnd
let tx_una t = t.snd_una
let tx_available t = 
  let inflight = Sequence.to_int32 (Sequence.sub t.tx_nxt t.snd_una) in
  let win = min t.cwnd t.tx_wnd in
  let avail_win = Int32.sub win inflight in
  match avail_win < Int32.of_int t.tx_mss with
  | true -> 0l
  | false -> avail_win

let tx_inflight t =
  t.tx_nxt <> t.snd_una


let alert_fast_rexmit t seq =
  let inflight = Sequence.to_int32 (Sequence.sub t.tx_nxt t.snd_una) in
  let newssthresh = max (Int32.div inflight 2l) (Int32.of_int (t.tx_mss * 2)) in
  let newcwnd = Int32.add newssthresh (Int32.of_int (t.tx_mss * 2)) in
  (*
  printf "ENTERING fast recovery inflight=%d, ssthresh=%d -> %d, cwnd=%d -> %d\n%!"
    (Int32.to_int inflight)
    (Int32.to_int t.ssthresh)
    (Int32.to_int newssthresh)
    (Int32.to_int t.cwnd)
    (Int32.to_int newcwnd);
    *)
  t.fast_recovery <- true;
  t.ssthresh <- newssthresh;
  t.rtt_timer_on <- false;  
  t.cwnd <- newcwnd

let rto t =
  match t.backoff_count with
  | 0 -> t.rto
  | _ -> t.rto *. (2. ** (float_of_int t.backoff_count))

let backoff_rto t =
  t.backoff_count <- t.backoff_count + 1;
  t.rtt_timer_on <- false;  
  t.rtt_timer_reset <- true  

let max_rexmits_done t =
  (t.backoff_count > 5)

let tx_totalbytes t =
  Sequence.(to_int (sub t.tx_nxt t.tx_isn))

let rx_totalbytes t =
  Sequence.(to_int (sub t.rx_nxt t.rx_isn))
  

