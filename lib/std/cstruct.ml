(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
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

open Bigarray
open Array1 

type buf = (char, int8_unsigned_elt, c_layout) Bigarray.Array1.t

type uint8 = int
type uint16 = int
type uint32 = int32
type uint64 = int64

let get_uint8 s off =
  Char.code (get s off)

let set_uint8 s off v =
  set s off (Char.chr v)

let sub_buffer src srcoff len =
  sub src srcoff len

let copy_buffer src srcoff len =
  let s = String.create len in
  for i = 0 to len - 1 do
    s.[i] <- get src (srcoff+i)
  done;
  s

let blit_buffer src srcoff dst dstoff len =
  let src = sub src srcoff len in
  let dst = sub dst dstoff len in
  blit src dst

let set_buffer src srcoff dst dstoff len =
  for i = srcoff to srcoff + len - 1 do
    set dst (dstoff+i) src.[i]
  done

module BE = struct

  let get_uint16 s off =
    let hi = get_uint8 s off in
    let lo = get_uint8 s (off+1) in
    (hi lsl 8) + lo

  let get_uint32 s off =
    let hi = get_uint16 s off in
    let lo = get_uint16 s (off+2) in
    Int32.(add (shift_left (of_int hi) 16) (of_int lo))

  let get_uint64 s off =
    let hi = get_uint32 s off in
    let lo = get_uint32 s (off+4) in 
    Int64.(add (shift_left (of_int32 hi) 32) (of_int32 lo))

  let set_uint16 s off v =
    set_uint8 s off (v lsr 8);
    set_uint8 s (off+1) (v land 0xff)

  let set_uint32 s off v =
    set_uint16 s off (Int32.(to_int (shift_right_logical v 16)));
    set_uint16 s (off+2) (Int32.(to_int (logand v 0xffff_l)))
  
  let set_uint64 s off v =
    set_uint32 s off (Int64.(to_int32 (shift_right_logical v 32)));
    set_uint32 s (off+4) (Int64.(to_int32 (logand v 0xffffffff_L)))

end

module LE = struct
  open Bigarray.Array1 

  let get_uint16 s off =
    let lo = get_uint8 s off in
    let hi = get_uint8 s (off+1) in
    (hi lsl 8) + lo

  let get_uint32 s off =
    let lo = get_uint16 s off in
    let hi = get_uint16 s (off+2) in
    Int32.(add (shift_left (of_int hi) 16) (of_int lo))

  let get_uint64 s off =
    let lo = get_uint32 s off in
    let hi = get_uint32 s (off+4) in 
    Int64.(add (shift_left (of_int32 hi) 32) (of_int32 lo))
  
  let set_uint16 s off v =
    set_uint8 s off (v land 0xff);
    set_uint8 s (off+1) (v lsr 8)

  let set_uint32 s off v =
    set_uint16 s (off+2) (Int32.(to_int (logand v 0xffff_l)));
    set_uint16 s off (Int32.(to_int (shift_right_logical v 16)))

  let set_uint64 s off v =
    set_uint32 s off (Int64.(to_int32 (logand v 0xffffffff_L)));
    set_uint32 s (off+4) (Int64.(to_int32 (shift_right_logical v 32)))
end

let len buf = dim buf

external base_offset : buf -> int = "caml_bigarray_base_offset"

let sub buf off len = sub buf off len

let to_string buf = 
  let sz = len buf in
  let s = String.create sz in
  for i = 0 to sz - 1 do
    s.[i] <- get buf i
  done;
  s

let shift buf off =
  sub buf off (len buf - off)

let split buf off =
  let header = sub buf 0 off in
  let body = sub buf off (len buf - off) in
  header, body

let hexdump buf =
  let c = ref 0 in
  for i = 0 to len buf - 1 do
    if !c mod 16 = 0 then print_endline "";
    printf "%.2x " (Char.code (get buf i));
    incr c;
  done;
  print_endline ""

(* Generate an iterator over a stream of packets *)
let iter hlen plenfn buf =
  let body = ref (Some buf) in
  fun () ->
    match !body with
    |Some buf ->
      (* Split the header frame *)
      let hdr, rest = split buf hlen in
      (* Determine the packet length from the header *)
      let plen = plenfn hdr in
      (* Generate the packet buffer *)
      let pbody = sub rest 0 plen in
      (* Skip the buffer to the next packet *)
      if len buf - hlen - plen > 0 then
        body := Some (shift rest plen)
      else
        body := None;
      Some (hdr, pbody)
    |None -> None
