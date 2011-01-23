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

exception Not_implemented of string

(* The receive queue stores out-of-order segments, and can
   coalesece them on input and pass on an ordered list up the
   stack to the application.
  
   It also looks for control messages and dispatches them to
   the Rtx queue to ack messages or close channels.
 *)
module Rx = struct

  (* Individual received TCP segment 
     TODO: this will change when IP fragments work *)
  type seg = Mpl.Tcp.o

  let seq (seg:seg) = Tcp_sequence.of_int32 seg#sequence
  let len (seg:seg) = seg#data_length + seg#fin + seg#syn
  let view (seg:seg) = seg#data_sub_view
  let ack (seg:seg) = seg#ack = 1
  let ack_number (seg:seg) = Tcp_sequence.of_int32 seg#ack_number

  (* Set of segments, ordered by sequence number *)
  module S = Set.Make(struct
    type t = seg
    let compare a b = Tcp_sequence.compare (seq a) (seq b)
  end)

  type t = S.t

  type q = {
    mutable segs: S.t;
    urx: OS.Istring.View.t list option Lwt_mvar.t; (* User receive channel *)
    tx_ack: Tcp_sequence.t Lwt_mvar.t; (* Acks of our transmitted segs *)
    rx_ack: Tcp_sequence.t Lwt_mvar.t; (* Acks to received segments *)
    wnd: Tcp_window.t;
  }

  let q ~urx ~wnd ~rx_ack ~tx_ack =
    let segs = S.empty in
    { segs; urx; tx_ack; rx_ack; wnd }

  let to_string t =
    String.concat ", " 
      (List.map (fun x -> sprintf "%lu[%d]"
      (Tcp_sequence.to_int32 (seq x)) (len x)) (S.elements t.segs))

  (* If there is a FIN flag at the end of this segment set.
     TODO: should look for a FIN and chop off the rest
     of the set as they may be orphan segments *)
  let fin q =
    try (S.max_elt q.segs)#fin = 1
    with Not_found -> false

  (* If there is a SYN flag in this segment set *)
  let syn q =
    try (S.max_elt q.segs)#syn = 1
    with Not_found -> false

  let is_empty q = S.is_empty q.segs

  (* Retrieve an istring list from a segment set and
     consume from the queue *)
  let views q =
    (* TODO: deal with overlapping fragments with istring
       subviews *)
    let vs = List.rev (S.fold (fun seg acc -> (view seg) :: acc) q.segs []) in
    q.segs <- S.empty;
    vs

  (* Given an input segment, the window information,
     and a receive queue, update the window,
     extract any ready segments into the user receive queue,
     and signal any acks to the Tx queue *)
  let input q seg =
    (* Check that the segment fits into the valid receive 
       window *)
    match Tcp_window.valid q.wnd (seq seg) with
    |false ->
      printf "TCP: rx invalid sequence, discarding\n%!";
      return ()
    |true -> begin
      (* Insert the latest segment *)
      let segs = S.add seg q.segs in
      (* Walk through the set and get a list of contiguous segments *)
      let ready, waiting = S.fold (fun seg acc ->
        match Tcp_sequence.compare (seq seg) (Tcp_window.rx_next q.wnd) with
        |(-1) ->
           (* Sequence number is in the past, probably an overlapping
              segment. Drop it for now, but TODO segment coalescing *)
           printf "TCP: segment in past %s\n%!" (Tcp_sequence.to_string (seq seg));
           acc
        |0 ->
           (* This is the next segment, so put it into the ready set
              and update the receive ack number *)
           let (ready,waiting) = acc in
           Tcp_window.rx_advance q.wnd (len seg);
           (S.add seg ready), waiting
        |1 -> 
           (* Sequence is in the future, so can't use it yet *)
           let (ready,waiting) = acc in
           ready, (S.add seg waiting)
        |_ -> assert false
        ) segs (S.empty, S.empty) in
      q.segs <- waiting;
      (* If the first segment is a SYN, then open the receive
         window *)
      if syn q then begin
        Tcp_window.rx_open ~rcv_wnd:seg#window ~isn:(seq seg) q.wnd;
        (* TODO: signal to user application that the channel is open?
           Doesn't seem to matter much at that level *)
      end;
      (* If the segment has an ACK, tell the transmit side *)
      let tx_ack =
        if ack seg then
          Lwt_mvar.put q.tx_ack (ack_number seg)
        else
          return () in
      (* Inform the user application of new data *)
      let urx_inform =
        Lwt_mvar.put q.urx (Some (List.map view (S.elements ready))) >>
        (* If the last ready segment has a FIN, then mark the receive
           window as closed and tell the application *)
        (if fin q then begin
          Tcp_window.rx_close q.wnd;
          if S.cardinal waiting != 0 then
            printf "TCP: warning, rx closed but waiting segs != 0\n%!"; 
          Lwt_mvar.put q.urx None
         end else return ())
      in
      tx_ack <&> urx_inform
    end

end

(* Transmitted segments are sent in-order, and may also be marked
   with control flags (such as urgent, or fin to mark the end).
*)
module Tx = struct

  type flags = |No_flags |Syn |Fin |Rst (* Either Syn/Fin/Rst allowed, but not combinations *)

  type xmit = flags:flags -> rx_ack:Tcp_sequence.t option -> seq:Tcp_sequence.t -> window:int -> unit OS.Istring.View.data -> OS.Istring.View.t Lwt.t

  type seg = {
    view: OS.Istring.View.t;
    flags: flags;
  }

  (* Sequence length of the segment *)
  let len seg =
    (match seg.flags with |No_flags |Rst -> 0 |Syn |Fin -> 1) +
    (OS.Istring.View.length seg.view)

  (* Queue of pre-transmission segments *)
  type q = {
    segs: seg Lwt_sequence.t;          (* Retransmitted segment queue *)
    xmit: xmit;                        (* Transmit packet to the wire *)
    rx_ack: Tcp_sequence.t Lwt_mvar.t; (* RX Ack thread that we've sent one *)
    rto: seg Lwt_mvar.t;               (* Mvar to append to retransmit queue *)
    wnd: Tcp_window.t;                 (* TCP Window information *)
  }

  let to_string seg =
    sprintf "[%s%d]" 
      (match seg.flags with |No_flags->"" |Syn->"SYN " |Fin ->"FIN " |Rst -> "RST ")
      (OS.Istring.View.length seg.view)

  let ack_segment q seg =
    printf "Tcp_segment.Tx.ack_segment: %s\n%!" (to_string seg);
    (* Take any action to the user transmit queue due to this being successfully
       ACKed *)
    ()

  let rto_t q tx_ack =
    printf "Tcp_segment.Tx.rto_thread: start\n%!";
    (* Mutex for q.segs *)
    let mutex = Lwt_mutex.create () in
    (* Listener thread for segments to hold for retransmission or ACK *)
    let rec rto_queue_t mutex =
      lwt seg = Lwt_mvar.take q.rto in
      Lwt_mutex.with_lock mutex (fun () ->
        printf "Tcp_segment.Tx.rto_queue: received seg\n%!";
        let _ = Lwt_sequence.add_r seg q.segs in
        (* TODO: kick the timer thread for retransmit *)
        return ()
      ) >>
      rto_queue_t mutex
    in
    (* Listen for incoming TX acks from the receive queue and ACK
       segments in our retransmission queue *)
    let rec tx_ack_t mutex =
      lwt seq_l = Lwt_mvar.take tx_ack in
      Lwt_mutex.with_lock mutex (fun () ->
        printf "Tcp_segment.Tx.tx_ack_t: received TX ack\n%!";
        (* Iterate through all the active segments, marking the ACK *)
        let ack_len = ref (Tcp_sequence.sub seq_l (Tcp_window.tx_una q.wnd)) in
        Lwt_sequence.iter_node_l (fun node ->
          let seg = Lwt_sequence.get node in
          let seg_len = Tcp_sequence.of_int (len seg) in
          if Tcp_sequence.geq !ack_len seg_len then begin
            (* This segment is now fully ack'ed *)
            Lwt_sequence.remove node;
            ack_segment q seg;
            ack_len := Tcp_sequence.sub !ack_len seg_len
          end else begin
            (* TODO: support partial ack *)
            printf "Tcp_segment.Tx.tx_ack_t: partial ack not yet supported\n%!";
            ack_len := Tcp_sequence.of_int32 0l
          end
        ) q.segs;
        Tcp_window.tx_ack q.wnd seq_l;
        tx_ack_t mutex
      )
    in
    (rto_queue_t mutex) <&> (tx_ack_t mutex)

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
  let output ?(flags=No_flags) q data = 
    (* Stamp the packet with the latest ack number *)
    let ack = Tcp_window.rx_next q.wnd in
    (* Transmit the packet to the wire
         TODO: deal with transmission soft/hard errors here RFC5461 *)
    let seq = Tcp_window.tx_nxt q.wnd in
    let window = Tcp_window.rx_wnd q.wnd in
    lwt view = q.xmit ~flags ~rx_ack:(Some ack) ~seq ~window data in
    (* Inform the RX ack thread that we've just sent one *)
    Lwt_mvar.put q.rx_ack ack >>
    (* Queue up segment just sent for retransmission if needed *)
    let seg = { view; flags } in
    printf "TCP_segment.Tx.queue: sent segment %s\n%!" (to_string seg);
    let seq_len = len seg in
    if seq_len > 0 then begin
      Tcp_window.tx_advance q.wnd seq_len;
      Lwt_mvar.put q.rto seg
    end else
      (* Segment is sequence-empty (e.g. an empty ACK or RST) so ignore it *)
      return ()
end

