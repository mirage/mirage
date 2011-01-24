(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

(* TCP options parsing *)

module I = OS.Istring.View

type t =
  |MSS of int                      (* RFC793 *)
  |Window_size_shift of int        (* RFC1323 2.2 *)
  |SACK_ok                         (* RFC2018 *)
  |SACK of (int32 * int32) array   (* RFC2018 *)
  |Timestamp of (int32 * int32)    (* RFC1323 3.2 *)
  |Unknown of (int * string)       (* RFC793 *)

let rec parse v off acc =
  match I.to_byte v off with
  |0 -> acc             (* End of options *)
  |1 -> parse v (off+1) acc  (* NOOP *)
  |2 -> parse v (off+4) (MSS (I.to_uint16_be v (off+2)) :: acc)
  |3 -> parse v (off+3) (Window_size_shift (I.to_byte v (off+2)) :: acc)
  |4 -> parse v (off+2) (SACK_ok :: acc)
  |5 ->
    let len = I.to_byte v (off+1) in
    let num = (len - 2) / 8 in
    let blocks = Array.init num (fun i ->
      (I.to_uint32_be v (off+2+(i*4))), (I.to_uint32_be v (off+4+(i*4)))) in
    parse v (off+2+len) (SACK blocks :: acc)
  |8 ->
    let r = (I.to_uint32_be v (off+2)), (I.to_uint32_be v (off+6)) in
    parse v (off+10) (Timestamp r :: acc) 
  |x ->
    let len = I.to_byte v (off+1) in
    let r = Unknown (x,(I.to_string v (off+2) len)) in
    parse v (off+2+len) (r::acc)

let of_packet (tcp:Mpl.Tcp.o) =
  if tcp#options_length = 0 then []
  else parse tcp#options_sub_view 0 []

let to_string = function
  |MSS m -> Printf.sprintf "MSS=%d" m
  |Window_size_shift b -> Printf.sprintf "Window>>%d" b
  |SACK_ok -> "SACK_ok"
  |SACK x -> Printf.(sprintf "SACK=(%s)" (String.concat ","
    (List.map (fun (l,r) -> sprintf "%lu,%lu" l r) (Array.to_list x))))
  |Timestamp (a,b) -> Printf.sprintf "Timestamp(%lu,%lu)" a b
  |Unknown (t,_) -> Printf.sprintf "%d?" t

let prettyprint s =
  Printf.sprintf "[ %s ]" (String.concat "; " (List.map to_string s))
