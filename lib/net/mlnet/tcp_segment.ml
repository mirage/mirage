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

(* Individual TCP segment *)
type seg = {
  seq: int32;           (* Sequence number *)
  len: int;             (* Length          *)
  packet: Mpl.Tcp.o;    (* Packet contents *)
}

(* Set of segments, ordered by position.
   TODO: Potentially not mod32 safe with overflow *)
module SegmentSet = Set.Make (
  struct
    type t = seg
    let compare a b = Pervasives.compare a b
  end
)

let segment_set_to_string segs =
  String.concat ", "
    (List.map (fun x -> Printf.sprintf "%lu[%d]" x.seq x.len)
      (SegmentSet.elements segs)
    )
    
(* Segment state for a connection *)
type t = {
  segs: SegmentSet.t; (* set of outstanding segments *)
  next_seq: int32;    (* next valid sequence number *)
}

let t next_seq =
  let segs = SegmentSet.empty in
  { segs; next_seq }

(* Given an input segment, return a list of in-order
   views to pass up to the application (and ack) *)
let coalesce (packet:Mpl.Tcp.o) con =
  (* Insert the latest segment *)
  let seg = { len=packet#data_length; seq=packet#sequence; packet } in
  Printf.printf "TCP Segment add: %lu\n%!" seg.seq;
  let segs = SegmentSet.add seg con.segs in
  (* Walk through the Set and get a list of contiguous segments *)
  let seq = ref con.next_seq in
  let ready,waiting = SegmentSet.partition
    (fun seg ->
       match seg.seq <= !seq with
       |true ->
          (* This is the next segment, or an overlapping earlier one *)
          seq := Int32.add !seq (Int32.of_int seg.len);
          true
       |false -> 
          (* Sequence is in the future, so can't use it yet *)
          false
    ) segs in
  (* Check for coalescing segments here *)
  Printf.printf "TCP Segments usable: %s, waiting: %s\n%!"
    (segment_set_to_string ready) (segment_set_to_string waiting);
  let con = { segs=waiting; next_seq=(!seq) } in
  ready, con
