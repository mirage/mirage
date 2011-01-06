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

open Printf
open Lwt

(* Received segments may be received out of order, and so
   are stored as an ordered list *)
module Rx = struct

  (* Individual received TCP segment *)
  type seg = {
    seq: Tcp_sequence.t;        (* Sequence number *)
    ack: Tcp_sequence.t option; (* Ack number      *)
    len: int;                   (* Length          *)
    fin: bool;                  (* Fin flag        *)
    syn: bool;                  (* Syn flag        *)
    view: OS.Istring.View.t;    (* Packet contents *)
  }

  let seg (packet:Mpl.Tcp.o) =
    let seq = Tcp_sequence.of_int32 packet#sequence in
    let len = packet#data_length in
    let view = packet#data_sub_view in
    let fin = packet#fin = 1 in
    let syn = packet#syn = 1 in
    let ack = if packet#ack = 1 then 
        Some (Tcp_sequence.of_int32 packet#ack_number)
      else
        None in
    { len; seq; fin; ack; syn; view }

  (* Set of segments, ordered by sequence number *)
  module S = Set.Make(struct
    type t = seg
    let compare a b = Tcp_sequence.compare a.seq b.seq
  end)

  type t = S.t

  type q = { mutable segs: S.t }
  let q () = { segs=S.empty }

  let to_string t =
    String.concat ", " 
      (List.map (fun x -> sprintf "%lu[%d]"
      (Tcp_sequence.to_int32 x.seq) x.len) (S.elements t.segs))

  (* If there is a FIN flag at the end of this segment set.
     TODO: should probably look for a FIN and chop off the rest
     of the set as they may be orphan segments *)
  let fin t =
    try
      (S.max_elt t).fin
    with
      Not_found -> false

  (* If there is a SYN flag in this segment set *)
  let syn t =
    try
      (S.min_elt t).syn
    with 
      Not_found -> true

  (* View of the segment *)
  let view seg = seg.view
   
  (* If there is a SYN or ACK flag in this segment *)
  let syn seg = seg.syn
  let ack seg = seg.ack 
 
  (* Iterate over segment set *)
  let iter fn t = S.iter fn t.segs

  (* Given an input segment and the window information,
     update the window and extract any ready segments *)
  let input ~wnd ~seg t =
    (* Check that the segment fits into the valid receive 
       window *)
    match Tcp_window.valid wnd seg.seq with
    |false ->
      printf "TCP: rx invalid sequence, discarding\n%!";
      {segs=S.empty}
    |true -> begin
      (* If the segment has an ACK, update our transmit window *)
      (match seg.ack with
        |None -> ()
        |Some ack -> Tcp_window.tx_ack wnd ack);
      (* Insert the latest segment *)
      let segs = S.add seg t.segs in
      (* Walk through the set and get a list of contiguous segments *)
      let ready, waiting = S.fold (fun seg acc ->
        match Tcp_sequence.compare seg.seq (Tcp_window.rx_next wnd) with
        |(-1) ->
           (* Sequence number is in the past, probably an overlapping
              segment. Drop it for now, but TODO segment coalescing *)
           printf "TCP: segment in past %s\n%!" (Tcp_sequence.to_string seg.seq);
           acc
        |0 ->
           (* This is the next segment, so put it into the ready set
              and update the receive ack number *)
           let (ready,waiting) = acc in
           Tcp_window.rx_advance wnd seg.len;
           (S.add seg ready), waiting
        |1 -> 
           (* Sequence is in the future, so can't use it yet *)
           let (ready,waiting) = acc in
           ready, (S.add seg waiting)
        |_ -> assert false
        ) segs (S.empty, S.empty) in
      t.segs <- waiting;
      (* If the last ready segment has a FIN, then mark the receive
         window as closed (this consumes a sequence number also ) *)
      if fin ready then begin
        Tcp_window.rx_close wnd;
        if S.cardinal waiting != 0 then
          printf "TCP: warning, rx closed but waiting segs != 0\n%!"
      end;
      printf "TCP Segments usable %d: waiting: [%s]\n%!"
        (S.cardinal ready) (to_string t);
      {segs=ready}
    end

end

(* Transmitted segments are sent in-order, and may also be marked
   with control flags (such as urgent, or fin to mark the end).
*)
module Tx = struct

  (* A seg has been queued up for transmission, but not yet sent.
     It may be coalesced with other segs in the queue depending on 
     the MSS and congestion status, or broken up into multiple
     segments if it's too large *)
  type seg = {
    syn: bool;
    ack: Tcp_sequence.t option;
    fin: bool;
    data: Mpl.Tcp.o OS.Istring.View.data;
  }

  let seg ?(syn=false) ?(ack=None) ?(fin=false) data =
    { fin; syn; ack; data }

  let ack seg = seg.ack
  let syn seg = seg.syn
  let fin seg = seg.fin
  let data seg = seg.data
 
  (* Queue of pre-transmission segments *)
  type q = seg Lwt_sequence.t
  let q () = Lwt_sequence.create ()

  let to_string seg =
    sprintf "[%s%s%s%s]" 
      (if seg.syn then "SYN " else "")
      (match seg.ack with
        |Some ack -> sprintf "ACK(%s) " (Tcp_sequence.to_string ack)
        |None -> "")
      (if seg.fin then "FIN " else "")
      (match seg.data with `Frag _ -> "frag" 
        |`Str _ -> "str" |`Sub _ -> "sub" |`None -> "empty")

  (* Queue a segment for eventual transmission.
     TODO: queue limit size and block if full *)
  let queue seg t = 
    printf "TCP_segment.Tx.queue: added segment %s\n%!" (to_string seg);
    let _ = Lwt_sequence.add_r seg t in
    return ()

  (* Given a maximum size, collect the next segment for
     transmission to the wire and return it.
     TODO: this currently just selects one, as we need composition
     operators for istrings (to append suspensions).
  *)
  let coalesce ~mss t =
    (* XXX TODO: enforce mss, and actually do some coalescion *)
    Lwt_sequence.take_opt_l t
end

module Rtx = struct
  (* A txseg has been transmitted, and is awaiting an ack from the 
     other side before it can be freed. We store the memoized 
     packet so it can be retransmitted without having to reevaluate
     the packet suspension. *)
  type seg = {
    seq: Tcp_sequence.t;
    len: int;  (* This is the sequence number length, including flags *)
    packet: Mpl.Tcp.o;
  }

  let seg packet =
    let seq = Tcp_sequence.of_int32 packet#sequence in
    (* SYN and FIN both consume 1 sequence space each *)
    let flags = packet#syn + packet#fin in
    let len = packet#data_length + flags in 
    { seq; len; packet }

  let to_string xseg =
    sprintf "[xseg seq %s len %d syn %d ack %d,%lu fin %d]"
      (Tcp_sequence.to_string xseg.seq) xseg.len xseg.packet#syn
      xseg.packet#ack xseg.packet#ack_number xseg.packet#fin

 (* Set of transmitted segments, ordered by sequence number *)
  module S = Set.Make(struct
    type t = seg
    let compare a b = Tcp_sequence.compare a.seq b.seq
  end)

  (* Queue of post-transmission segments awaiting acks *)
  type q = { mutable segs: S.t }
  let q () = { segs=S.empty }

  (* Queue a segment on the retransmission queue *)
  let queue ~wnd seg t =
    printf "Tcp_segment.Rtx: queued segment %s\n%!" (to_string seg);
    (* TODO: dont queue up empty data segments like ACKS *)
    t.segs <- S.add seg t.segs;
    (* Advance the transmit window *)
    Tcp_window.tx_advance wnd seg.len;
    return ()

  (* Register a partial ack, and return true if this fully acks the 
     segment.
     TODO: not yet supported *)
  let partial_ack xseg seq_l seq_r =
    printf "TCP_segment.Tx: ERROR partial ack not supported yet\n%!";
    false

  (* Indicate that a range of sequence numbers have been ACKed and
     can be removed. Also tell another thread if a non-zero amount
     has been acked *)
  let mark_ack cond xseg_q seq_l seq_r =
    printf "TCP_segment.Tx: mark ack segment %s-%s\n%!"
      (Tcp_sequence.to_string seq_l) (Tcp_sequence.to_string seq_r);
    let acked,unacked = S.partition
      (fun xseg ->
         (* Check if the acked segment fully overlaps this segment *)
         match Tcp_sequence.leq seq_l xseg.seq with
         |true -> begin (* Acked segment starts before or on this segment *)
           let xseg_r = Tcp_sequence.(add xseg.seq (of_int xseg.len)) in
           match Tcp_sequence.geq seq_r xseg_r with
           |true -> (* ack edge is greater than this segment, so it is acked *)
             true
           |false -> begin (* ack edge is less than this segment, so check if partial ack *)
             match Tcp_sequence.leq seq_r xseg.seq with
             |true -> (* TODO: possibly a duplicate ACK , see RFC2581 heuristics *)
               false
             |false -> (* this is a partial ack *)
               partial_ack xseg seq_l seq_r
           end
         end
         |false -> (* starts after this segment, so is a partial ack *)
           partial_ack xseg seq_l seq_r 
      ) xseg_q.segs in
    xseg_q.segs <- unacked;
    (* Calculate the total sequence length of acked segments *)
    let len = try
      Tcp_sequence.(to_int (sub seq_r (S.min_elt acked).seq))
    with
      Not_found -> 0 in
    if len > 0 then
      Lwt_condition.signal cond len

end
