(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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

(* The receive queue stores out-of-order segments, and can
   coalesece them on input and pass on an ordered list up the
   stack to the application.
  
   It also looks for control messages and dispatches them to
   the Rtx queue to ack messages or close channels.
 *)
module Rx = struct

  (* Individual received TCP segment 
     TODO: this will change when IP fragments work *)
  type seg = {
    sequence: Sequence.t;
    data: Bitstring.t;
    fin: bool;
    syn: bool;
    ack: bool;
    ack_number: Sequence.t;
    window: int;
  }

  let make ~sequence ~fin ~syn ~ack ~ack_number ~window ~data =
    { sequence; fin; syn; ack; ack_number; window; data }

  let len seg = 
    (Bitstring.bitstring_length seg.data / 8) +
    (if seg.fin then 1 else 0) +
    (if seg.syn then 1 else 0)

  (* Set of segments, ordered by sequence number *)
  module S = Set.Make(struct
    type t = seg
    let compare a b = Sequence.compare a.sequence b.sequence
  end)

  type t = S.t

  type q = {
    mutable segs: S.t;
    rx_data: Bitstring.t list option Lwt_mvar.t; (* User receive channel *)
    tx_ack: Sequence.t Lwt_mvar.t; (* Acks of our transmitted segs *)
    tx_wnd_update: int Lwt_mvar.t; (* Received updates to the transmit window *)
    wnd: Window.t;
  }

  let q ~rx_data ~wnd ~tx_ack ~tx_wnd_update =
    let segs = S.empty in
    { segs; rx_data; tx_ack; wnd; tx_wnd_update }

  let to_string t =
    String.concat ", " 
      (List.map (fun seg -> sprintf "%lu[%d]" (Sequence.to_int32 seg.sequence) (len seg))
       (S.elements t.segs))

  (* If there is a FIN flag at the end of this segment set.
     TODO: should look for a FIN and chop off the rest
     of the set as they may be orphan segments *)
  let fin q =
    try (S.max_elt q).fin
    with Not_found -> false

  (* If there is a SYN flag in this segment set *)
  let syn q =
    try (S.max_elt q).syn
    with Not_found -> false

  (* Determine the transmit window, from the last segment *)
  let window q =
    try (S.max_elt q).window
    with Not_found -> 0

  let is_empty q = S.is_empty q.segs

  (* Given an input segment, the window information,
     and a receive queue, update the window,
     extract any ready segments into the user receive queue,
     and signal any acks to the Tx queue *)
  let input q seg =
    (* Check that the segment fits into the valid receive 
       window *)
    match Window.valid q.wnd seg.sequence with
    |false -> return ()
    |true -> begin
      (* Insert the latest segment *)
      let segs = S.add seg q.segs in
      (* Walk through the set and get a list of contiguous segments *)
      let ready, waiting = S.fold (fun seg acc ->
        match Sequence.compare seg.sequence (Window.rx_nxt q.wnd) with
        |(-1) ->
           (* Sequence number is in the past, probably an overlapping
              segment. Drop it for now, but TODO segment coalescing *)
           acc
        |0 ->
           (* This is the next segment, so put it into the ready set
              and update the receive ack number *)
           let (ready,waiting) = acc in
           Window.rx_advance q.wnd (len seg);
           (S.add seg ready), waiting
        |1 -> 
           (* Sequence is in the future, so can't use it yet *)
           let (ready,waiting) = acc in
           ready, (S.add seg waiting)
        |_ -> assert false
        ) segs (S.empty, S.empty) in
      q.segs <- waiting;

      (* If the segment has an ACK, tell the transmit side *)
      let tx_ack =
        if seg.ack then
          Lwt_mvar.put q.tx_ack seg.ack_number
        else
          return () in

      (* Inform the window thread of updates to the transmit window *)
      let window_update =
        Lwt_mvar.put q.tx_wnd_update (window ready) in

      (* Inform the user application of new data *)
      let urx_inform =
        (* TODO: deal with overlapping fragments *)
        let elems = List.rev (S.fold (fun seg acc ->
          if Bitstring.bitstring_length seg.data > 0 then seg.data :: acc else acc
         )ready []) in
        Lwt_mvar.put q.rx_data (Some elems) >>
        (* If the last ready segment has a FIN, then mark the receive
           window as closed and tell the application *)
        (if fin ready then begin
          if S.cardinal waiting != 0 then
            printf "TCP: warning, rx closed but waiting segs != 0\n%!"; 
          Lwt_mvar.put q.rx_data None
         end else return ())
      in
      tx_ack <&> urx_inform <&> window_update
    end

end

(* Transmitted segments are sent in-order, and may also be marked
   with control flags (such as urgent, or fin to mark the end).
*)
module Tx = struct

  type flags = (* Either Syn/Fin/Rst allowed, but not combinations *)
    No_flags
   |Syn
   |Fin
   |Rst

  type xmit = flags:flags -> wnd:Window.t -> options:Options.ts -> Bitstring.t -> Bitstring.t list Lwt.t

  type seg = {
    data: Bitstring.t;
    flags: flags;
  }

  (* Sequence length of the segment *)
  let len seg =
    (match seg.flags with |No_flags |Rst -> 0 |Syn |Fin -> 1) +
    (Bitstring.bitstring_length seg.data / 8)

  (* Queue of pre-transmission segments *)
  type q = {
    segs: seg Lwt_sequence.t;          (* Retransmitted segment queue *)
    xmit: xmit;                        (* Transmit packet to the wire *)
    rx_ack: Sequence.t Lwt_mvar.t; (* RX Ack thread that we've sent one *)
    rto: seg Lwt_mvar.t;               (* Mvar to append to retransmit queue *)
    wnd: Window.t;                 (* TCP Window information *)
  }

  let to_string seg =
    sprintf "[%s%d]" 
      (match seg.flags with |No_flags->"" |Syn->"SYN " |Fin ->"FIN " |Rst -> "RST ")
      (len seg)

  let ack_segment q seg =
    (* Take any action to the user transmit queue due to this being successfully
       ACKed *)
    ()

  let rto_t q tx_ack =
    (* Mutex for q.segs *)
    (* Listener thread for segments to hold for retransmission or ACK *)
    let rec rto_queue_t () =
      lwt seg = Lwt_mvar.take q.rto in
      let _ = Lwt_sequence.add_r seg q.segs in
      (* TODO: kick the timer thread for retransmit *)
      rto_queue_t ()
    in
    (* Listen for incoming TX acks from the receive queue and ACK
       segments in our retransmission queue *)
    let rec tx_ack_t () =
      lwt seq_l = Lwt_mvar.take tx_ack in
      (* Iterate through all the active segments, marking the ACK *)
      let ack_len = ref (Sequence.sub seq_l (Window.tx_una q.wnd)) in
      Lwt_sequence.iter_node_l (fun node ->
        let seg = Lwt_sequence.get node in
        let seg_len = Sequence.of_int (len seg) in
        match Sequence.to_int32 !ack_len with
        |0l -> ()
        |_ ->
          if Sequence.geq !ack_len seg_len then begin
            (* This segment is now fully ack'ed *)
            Lwt_sequence.remove node;
            ack_segment q seg;
            ack_len := Sequence.sub !ack_len seg_len
          end else begin
            (* TODO: support partial ack *)
           ack_len := Sequence.of_int32 0l
          end
      ) q.segs;
      Window.tx_ack q.wnd seq_l;
      tx_ack_t ()
    in
    (rto_queue_t ()) <?> (tx_ack_t ())

  let q ~xmit ~wnd ~rx_ack ~tx_ack =
    let rto = Lwt_mvar.create_empty () in
    let segs = Lwt_sequence.create () in
    let q = { xmit; wnd; rx_ack; rto; segs } in
    let t = rto_t q tx_ack in
    q, t

  (* Queue a segment for transmission. May block if:
       - There is no transmit window available.
       - The wire transmit function blocks.
     The transmitter should check that the segment size will
     will not be greater than the transmit window.
   *)
  let output ?(flags=No_flags) ?(options=[]) q data = 
    (* Transmit the packet to the wire
         TODO: deal with transmission soft/hard errors here RFC5461 *)
    let {wnd} = q in
    let ack = Window.tx_nxt wnd in
    lwt view = q.xmit ~flags ~wnd ~options data in
    (* Inform the RX ack thread that we've just sent one *)
    Lwt_mvar.put q.rx_ack ack >>
    (* Queue up segment just sent for retransmission if needed *)
    let seg = { data; flags } in
    let seq_len = len seg in
    if seq_len > 0 then begin
      Window.tx_advance q.wnd seq_len;
      Lwt_mvar.put q.rto seg
    end else
      (* Segment is sequence-empty (e.g. an empty ACK or RST) so ignore it *)
      return ()
end

