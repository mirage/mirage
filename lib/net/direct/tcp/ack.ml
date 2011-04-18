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
  val t : send_ack:Sequence.t Lwt_mvar.t -> last:Sequence.t -> t 

  (* called when new data is received *)
  val receive: t -> Sequence.t -> unit Lwt.t

  (* called when an ack is transmitted from elsewhere *)
  val transmit: t -> Sequence.t -> unit Lwt.t
end

(* Transmit ACKs immediately, the dumbest (and simplest) way *)
module Immediate : M = struct

  type t = Sequence.t Lwt_mvar.t

  let t ~send_ack ~last = send_ack

  let receive t ack_number =
    Lwt_mvar.put t ack_number

  let transmit t ack_number =
    return ()
end

(* Delayed ACKs *)
module Delayed : M = struct

  (* ev: Event mvar of transmitted/received packets
     send_ack: Write to this mvar to transmit an empty ACK
  *)
  type ev = Tx of Sequence.t | Rx of Sequence.t

  type r = {
    ev: ev Lwt_mvar.t;
    send_ack: Sequence.t Lwt_mvar.t;
  }

  type t = r * unit Lwt.t

  let transmit r ack_number =
    Lwt_mvar.put r.send_ack ack_number
 
  let rec timer r =
    (* Wait for a received segment update to start the timer *)
    lwt ev = Lwt_mvar.take r.ev in
    match ev with 
    |Tx seq ->
      timer r
    |Rx seq ->
      (* Start the delayed ACK timer *)
      (* Delay thread that transmits after 200ms *)
      let max_time = 0.2 in
      let delay =
        OS.Time.sleep max_time >>
        transmit r seq >>
        timer r 
      in
      (* Continuation thread that cancels the timer if something
         else transmits an ACK in the meanwhile *)
      let other_ev =
        lwt ev = Lwt_mvar.take r.ev in
        match ev with
        |Rx seq ->
          (* If another packet is received, transmit an immediate ACK 
             to the newest sequence number just received *)
          Lwt.cancel delay;
          transmit r seq >>
          timer r
        |Tx seq' ->
          (* TODO: assert seq' == seq *)
          Lwt.cancel delay;
          timer r
       in
       (* Pick between the two threads *)
       delay <?> other_ev
    
  let t ~send_ack ~last : t =
    let ev = Lwt_mvar.create_empty () in
    let r = { send_ack; ev } in
    (r, timer r)

  (* Advance the received ACK count *)
  let receive (r,t) ack_number = 
    Lwt_mvar.put r.ev (Rx ack_number)

  (* Indicate that an ACK has been transmitted *)
  let transmit (r,t) ack_number =
    Lwt_mvar.put r.ev (Tx ack_number)
end
