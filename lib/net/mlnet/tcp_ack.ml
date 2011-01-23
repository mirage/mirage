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

  (* ack: put mvar to trigger the transmission of an ack *)
  val t : ack:Tcp_sequence.t Lwt_mvar.t -> last:Tcp_sequence.t -> t 

  (* called when new data is received *)
  val receive: t -> Tcp_sequence.t -> unit Lwt.t

  (* called when an ack is transmitted from elsewhere *)
  val transmit: t -> Tcp_sequence.t -> unit Lwt.t
end

(* Transmit ACKs immediately, the dumbest (and simplest) way *)
module Immediate : M = struct

  type t = Tcp_sequence.t Lwt_mvar.t

  let t ~ack ~last = ack

  let receive t ack_number =
    Lwt_mvar.put t ack_number

  let transmit t ack_number =
    return ()
end

(* Delayed ACKs *)
module Delayed : M = struct

  (* rx: When new data is received, the highest new sequence number sent here.
     tx: When any ack update is sent (e.g. piggybacked on tx data), tx is notified.
     ack_cond: When a delayed ack timer fires, ack_cond is notified.
  *)
  type r = {
    mutable count: int;
    mutable last: Tcp_sequence.t;
    rx: Tcp_sequence.t Lwt_mvar.t;
    tx: Tcp_sequence.t Lwt_mvar.t;
    ack: Tcp_sequence.t Lwt_mvar.t;
  }

  type t = r * unit Lwt.t

  let transmit t ack_number =
    Lwt_mvar.put t.ack ack_number
 
  let rec timer t =
    (* Wait for a received segment update *)
    lwt ack_number = Lwt_mvar.take t.rx in
    t.count <- t.count + 1;
    (* Decide if we need to send an ack straight away *)
    if t.count > 2 then begin
      (* TODO: RFC1122 4.2.3.2 actually says that in a stream of
         "full-sized" segments there should be an ACK every two
         seconds. We just do it for every other segment right now *)
      transmit t ack_number >>
      timer t
    end else begin
      (* Delay thread that transmits after 200ms *)
      let delay =
        OS.Time.sleep 0.1 >>
        (printf "ACK delay thread fired\n%!";
        transmit t ack_number >>
        timer t) in
      (* Continuation thread that cancels the timer if something
         else transmits an ACK in the meanwhile *)
      let continue =
        lwt _ = Lwt_mvar.take t.tx in
        (printf "ACK delay thread cancelled\n%!";
        Lwt.cancel delay;
        timer t) in
      (* Pick between the two threads *)
      continue <?> delay
    end

  let t ~ack ~last : t =
    let rx = Lwt_mvar.create_empty () in
    let tx = Lwt_mvar.create_empty () in
    let r = { count=0; last; ack; rx; tx } in
    (r, timer r)

  (* Advance the received ACK count *)
  let receive (t,_) ack_number = 
    if Tcp_sequence.lt t.last ack_number then
      Lwt_mvar.put t.rx ack_number
    else
      return ()

  (* Indicate that an ACK has been transmitted *)
  let transmit (t,_) ack_number =
    if Tcp_sequence.lt t.last ack_number then begin
      t.last <- ack_number;
      t.count <- 0;
      Lwt_mvar.put t.tx ack_number
    end else
      return ()
end
