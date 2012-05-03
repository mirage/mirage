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
open State

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

  let seg_to_string seg =
    sprintf "TCP: RX seg seq=%s fin=%b syn=%b ack=%b acknum=%s win=%d"
       (Sequence.to_string seg.sequence) seg.fin seg.syn seg.ack
       (Sequence.to_string seg.ack_number) seg.window

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
    rx_data: (Bitstring.t list option * int option) Lwt_mvar.t; (* User receive channel *)
    tx_ack: (Sequence.t * int) Lwt_mvar.t; (* Acks of our transmitted segs *)
    wnd: Window.t;
    state: State.t;
  }

  let q ~rx_data ~wnd ~state ~tx_ack =
    let segs = S.empty in
    { segs; rx_data; tx_ack; wnd; state }

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
    let force_ack = ref false in
    match Window.valid q.wnd seg.sequence with
    |false -> return ()
    |true -> begin
      (* Insert the latest segment *)
      let segs = S.add seg q.segs in
      (* Walk through the set and get a list of contiguous segments *)
      let ready, waiting = S.fold (fun seg acc ->
        match Sequence.compare seg.sequence (Window.rx_nxt_inseq q.wnd) with
        |(-1) ->
           (* Sequence number is in the past, probably an overlapping
              segment. Drop it for now, but TODO segment coalescing *)
           force_ack := true;
           acc
        |0 ->
           (* This is the next segment, so put it into the ready set
              and update the receive ack number *)
           let (ready,waiting) = acc in
           Window.rx_advance_inseq q.wnd (len seg);
           (S.add seg ready), waiting
        |1 -> 
           (* Sequence is in the future, so can't use it yet *)
           force_ack := true;
           let (ready,waiting) = acc in
           ready, (S.add seg waiting)
        |_ -> assert false
        ) segs (S.empty, S.empty) in
      q.segs <- waiting;

      (* If the segment has an ACK, tell the transmit side *)
      let tx_ack =
        if seg.ack then begin
	  tick q.state (Recv_ack seg.ack_number);
          Lwt_mvar.put q.tx_ack (seg.ack_number, (window ready))
        end else
          return () in

      (* Inform the user application of new data *)
      let urx_inform =
        (* TODO: deal with overlapping fragments *)
        let elems_r, winadv = S.fold (fun seg (acc_l, acc_w) ->
          (if Bitstring.bitstring_length seg.data > 0 then seg.data :: acc_l else acc_l), ((len seg) + acc_w)
         )ready ([], 0) in
        let elems = List.rev elems_r in

        let w = if !force_ack || winadv > 0 then Some winadv else None in
        Lwt_mvar.put q.rx_data (Some elems, w) >>
        (* If the last ready segment has a FIN, then mark the receive
           window as closed and tell the application *)
        (if fin ready then begin
          if S.cardinal waiting != 0 then
            printf "TCP: warning, rx closed but waiting segs != 0\n%!"; 
          Lwt_mvar.put q.rx_data (None, Some 0)
         end else return ())
      in
      tx_ack <&> urx_inform
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
   |Psh

  type xmit = flags:flags -> wnd:Window.t -> options:Options.ts ->
              seq:Sequence.t -> Bitstring.t -> unit Lwt.t

  type seg = {
    data: Bitstring.t;
    flags: flags;
    seq: Sequence.t;
  }

  (* Sequence length of the segment *)
  let len seg =
    (match seg.flags with |No_flags |Psh |Rst -> 0 |Syn |Fin -> 1) +
    (Bitstring.bitstring_length seg.data / 8)

  (* Queue of pre-transmission segments *)
  type q = {
    segs: seg Lwt_sequence.t;          (* Retransmitted segment queue *)
    xmit: xmit;                        (* Transmit packet to the wire *)
    rx_ack: Sequence.t Lwt_mvar.t; (* RX Ack thread that we've sent one *)
    wnd: Window.t;                 (* TCP Window information *)
    state: State.t;
    tx_wnd_update: int Lwt_mvar.t; (* Received updates to the transmit window *)
    rexmit_timer: Tcptimer.t;      (* Retransmission timer for this connection *)
    mutable dup_acks: int;         (* dup ack count for re-xmits *)
  }

  let to_string seg =
    sprintf "[%s%d]" 
      (match seg.flags with |No_flags->"" |Syn->"SYN " |Fin ->"FIN " |Rst -> "RST " |Psh -> "PSH ")
      (len seg)

  let ack_segment q seg =
    (* Take any action to the user transmit queue due to this being successfully
       ACKed *)
    ()

  (* URG_TODO: Add sequence number to the Syn_rcvd rexmit to only rexmit most recent *)
  let ontimer xmit st segs wnd seq =
    match state st with
    | Syn_rcvd _ | Established | Fin_wait_1 _ | Close_wait | Last_ack _ -> begin
	match Lwt_sequence.peek_opt_l segs with 
	| None ->
            Tcptimer.Stoptimer
	| Some rexmit_seg ->
            match rexmit_seg.seq = seq with
            | false ->
		(* printf "PUSHING TIMER - new time = %f, new seq = %d\n%!"
		   (Window.rto wnd) (Sequence.to_int rexmit_seg.seq); *)
		Tcptimer.ContinueSetPeriod (Window.rto wnd, rexmit_seg.seq)
            | true ->
		if (Window.max_rexmits_done wnd) then begin
		  (* TODO - include more in log msg like ipaddrs *)
		  printf "Max retransmits reached for connection - terminating\n%!";
		  tick st Timeout;
		  Tcptimer.Stoptimer
		end else begin
		  let flags = rexmit_seg.flags in
		  let options = [] in (* TODO: put the right options *)
		  printf "TCP retransmission on timer seq = %d\n%!"
                    (Sequence.to_int rexmit_seg.seq);
		  let _ = xmit ~flags ~wnd ~options ~seq rexmit_seg.data in
		  Window.backoff_rto wnd;
		  (* printf "PUSHING TIMER - new time = %f, new seq = %d\n%!"
                     (Window.rto wnd) (Sequence.to_int rexmit_seg.seq); *)
		  Tcptimer.ContinueSetPeriod (Window.rto wnd, rexmit_seg.seq)
		end
    end
    | _ -> 
        Tcptimer.Stoptimer


  let rto_t q tx_ack =
    (* Listen for incoming TX acks from the receive queue and ACK
       segments in our retransmission queue *)
    let rec tx_ack_t () =
      let serviceack dupack ack_len seq win = match dupack with
      | true ->
          q.dup_acks <- q.dup_acks + 1;
          if 3 = q.dup_acks then begin
            (* retransmit the bottom of the unacked list of packets *)
            let rexmit_seg = Lwt_sequence.peek_l q.segs in
            (* printf "TCP fast retransmission seq = %d, dupack = %d\n%!"
                    (Sequence.to_int rexmit_seg.seq) (Sequence.to_int seq); *)
            let {wnd} = q in
            let flags=rexmit_seg.flags in
            let options=[] in (* TODO: put the right options *)
            let _ = q.xmit ~flags ~wnd ~options ~seq rexmit_seg.data in
            (* alert window module to fall into fast recovery *)
            Window.alert_fast_rexmit q.wnd seq
          end
      | false ->
          q.dup_acks <- 0;
          let rec clearsegs ack_remaining segs =
            match ack_remaining > 0l with
            | false -> 0l (* here we return 0l instead of ack_remaining in case
                             the ack was an old packet in the network *)
            | true ->
		match Lwt_sequence.take_opt_l segs with
		| None ->
                    printf "TCP: Dubious ACK received\n%!";
                    ack_remaining
		| Some s ->
                    let seg_len = (Int32.of_int (len s)) in
                    match ack_remaining < seg_len with
                    | true ->
			printf "TCP: Partial ACK received\n%!";
			(* return uncleared segment to the sequence *)
			let _ = Lwt_sequence.add_l s segs in
			ack_remaining
                    | false ->
			ack_segment q s;
			clearsegs (Int32.sub ack_remaining seg_len) segs
          in
          let partleft = clearsegs (Sequence.to_int32 ack_len) q.segs in
          Window.tx_ack q.wnd (Sequence.sub seq (Sequence.of_int32 partleft)) win
      in
      lwt (seq, win) = Lwt_mvar.take tx_ack in
      let ack_len = Sequence.sub seq (Window.tx_una q.wnd) in
      let dupacktest () = ((0l = (Sequence.to_int32 ack_len)) &&
                           ((Window.tx_wnd q.wnd) = (Int32.of_int win)) &&
                           (not (Lwt_sequence.is_empty q.segs)))
      in
      serviceack (dupacktest ()) ack_len seq win;
      (* Inform the window thread of updates to the transmit window *)
      Lwt_mvar.put q.tx_wnd_update win >>
      tx_ack_t ()
    in
    tx_ack_t ()


  let q ~xmit ~wnd ~state ~rx_ack ~tx_ack ~tx_wnd_update =
    let segs = Lwt_sequence.create () in
    let dup_acks = 0 in
    let expire = ontimer xmit state segs wnd in
    let period = Window.rto wnd in
    let rexmit_timer = Tcptimer.t ~period ~expire in
    let q = { xmit; wnd; state; rx_ack; segs; tx_wnd_update; rexmit_timer; dup_acks } in
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
    let ack = Window.rx_nxt wnd in
    let seq = Window.tx_nxt wnd in
    let seg = { data; flags; seq } in
    let seq_len = len seg in
    Window.tx_advance q.wnd seq_len;
    (* Queue up segment just sent for retransmission if needed *)
    let q_rexmit () =
      match seq_len > 0 with
      | false -> return ()
      | true ->
          let _ = Lwt_sequence.add_r seg q.segs in
          let p = Window.rto q.wnd in
          Tcptimer.start q.rexmit_timer ~p seg.seq
    in
    q_rexmit () >> 
    lwt view = q.xmit ~flags ~wnd ~options ~seq data in
    (* Inform the RX ack thread that we've just sent one *)
    Lwt_mvar.put q.rx_ack ack 
end

