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

(* Received segments may be received out of order, and so
   are stored as an ordered set *)
module Rx = struct

  (* Individual received TCP segment *)
  type seg = {
    seq: int32;                 (* Sequence number *)
    len: int;                   (* Length          *)
    fin: bool;                  (* Fin flag        *)
    view: OS.Istring.View.t;    (* Packet contents *)
  }

  let seg (packet:Mpl.Tcp.o) =
    let len = packet#data_length in
    let seq = packet#sequence in
    let view = packet#data_sub_view in
    let fin = packet#fin = 1 in
    { len; seq; fin; view }
 
  (* Set of segments, ordered by position.
     TODO: not mod32 safe with overflow *)
  module S = Set.Make ( struct
    type t = seg
    let compare a b = Pervasives.compare a b
  end)

  type t = S.t

  let empty = S.empty

  let iter fn =
    S.iter (fun seg -> fn seg.view)

  let to_string segs =
    String.concat ", "
      (List.map (fun x -> sprintf "%lu[%d]" x.seq x.len)
        (S.elements segs)
      )

  (* Given an input segment and the next expected sequence
     number, return (ready segments, waiting segments) *)
  let input ~seg ~rcv_nxt ~segs =
    (* Insert the latest segment *)
    printf "TCP Segment add: %lu\n%!" seg.seq;
    let segs = S.add seg segs in
    (* Walk through the Set and get a list of contiguous segments *)
    let seq = ref rcv_nxt in
    let ready, waiting = S.partition
      (fun seg ->
         printf "found: seq=%lu seg.seq=%lu\n%!" !seq seg.seq;
         match seg.seq <= !seq with
         | true ->
            (* This is the next segment, or an overlapping earlier one *)
            seq := Int32.add !seq (Int32.of_int seg.len);
            printf "usable!\n%!";
            true
         | false -> 
            (* Sequence is in the future, so can't use it yet *)
            false
      ) segs in
    (* Check for coalescing segments here *)
    printf "TCP Segments usable: [%s] waiting: %s\n%!"
      (to_string ready) (to_string waiting);
    ready, waiting

end

(* Transmitted segments are sent in-order, and may also be marked
   with control flags (such as urgent, or fin to mark the end).
   TODO: coalescion based on MSS, retransmission.
*)
module Tx = struct

  type seg = {
    urg: bool;
    fin: bool;
    data: Mpl.Tcp.o OS.Istring.View.data;
  }

  let seg ?(urg=false) ?(fin=false) data =
    { urg; fin; data }

  type t = seg list

  let empty : t = [] 

  (* Given a maximum size, collect a set of data for
     transmission.
     TODO: this currently just selects one, as we need composition
     operators for istrings (to append suspensions).
  *)
  let output (mss:int) (segs:t) : (seg option * t) =
    (* XXX TODO: enforce mss *)
    match segs with
    | hd :: tl ->
        Some hd, tl
    | [] -> None, []

  let to_string (segs:t) =
    String.concat ", " (List.map (fun x -> ".") segs)

  let is_empty (t:t) =
    match t with
    | [] -> true
    | _ -> false

  let with_fin seg = { seg with fin=true }
  let fin seg = seg.fin
  let data seg = seg.data
  let urg seg = seg.urg

end

