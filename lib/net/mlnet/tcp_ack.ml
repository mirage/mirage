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

(* General signature for all the ack modules *)
module type M = sig
  type t
  val t : unit Lwt_condition.t -> Tcp_sequence.t -> t

  val receive: t -> Tcp_sequence.t -> unit
  val transmit: t -> Tcp_sequence.t -> unit
end

(* Transmit ACKs immediately, the dumbest (and simplest) way *)
module Immediate : M = struct

  type t = unit Lwt_condition.t

  let t ack_cond last = ack_cond

  let receive t ack_number =
    Lwt_condition.signal t ()

  let transmit t ack_number =
    ()
end

(* Delayed ACKs *)
module Delayed : M = struct

  (* rx_cond: When new data is received, the highest new sequence number sent here.
     tx_cond: When any ack update is sent (e.g. piggybacked on tx data), tx_cond is notified.
     ack_cond: When a delayed ack timer fires, ack_cond is notified.
  *)
  type r = {
    mutable count: int;
    mutable last: Tcp_sequence.t;
    rx_cond: Tcp_sequence.t Lwt_condition.t;
    tx_cond: Tcp_sequence.t Lwt_condition.t;
    ack_cond: unit Lwt_condition.t;
  }

  type t = r * unit Lwt.t

  let transmit t ack_number =
    Lwt_condition.signal t.ack_cond ()
 
  let rec timer t =
    (* Wait for a received segment update *)
    lwt ack_number = Lwt_condition.wait t.rx_cond in
    t.count <- t.count + 1;
    (* Decide if we need to send an ack straight away *)
    if t.count > 2 then begin
      (* TODO: RFC1122 4.2.3.2 actually says that in a stream of
         "full-sized" segments there should be an ACK every two
         seconds. We just do it for every other segment right now *)
      transmit t ack_number;
      timer t
    end else begin
      (* Delay thread that transmits after 200ms *)
      let delay =
        OS.Time.sleep 0.1 >>
        (printf "ACK delay thread fired\n%!";
        transmit t ack_number;
        timer t) in
      (* Continuation thread that cancels the timer if something
         else transmits an ACK in the meanwhile *)
      let continue =
        Lwt_condition.wait t.tx_cond >>
        (printf "ACK delay thread cancelled\n%!";
        Lwt.cancel delay;
        timer t) in
      (* Pick between the two threads *)
      continue <?> delay
    end

  let t ack_cond last : t =
    let rx_cond = Lwt_condition.create () in
    let tx_cond = Lwt_condition.create () in
    let r = { count=0; last; ack_cond; rx_cond; tx_cond } in
    (r, timer r)

  (* Advance the received ACK count *)
  let receive (t,_) ack_number = 
    if Tcp_sequence.lt t.last ack_number then
      Lwt_condition.signal t.rx_cond ack_number

  (* Indicate that an ACK has been transmitted *)
  let transmit (t,_) ack_number =
    if Tcp_sequence.lt t.last ack_number then begin
      t.last <- ack_number;
      t.count <- 0;
      Lwt_condition.signal t.tx_cond ack_number
    end
end
