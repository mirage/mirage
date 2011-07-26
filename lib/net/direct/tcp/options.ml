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

type t =
  |MSS of int                    (* RFC793 *)
  |Window_size_shift of int      (* RFC1323 2.2 *)
  |SACK_ok                       (* RFC2018 *)
  |SACK of (int32 * int32) list  (* RFC2018 *)
  |Timestamp of int32 * int32    (* RFC1323 3.2 *)
  |Unknown of int * string       (* RFC793 *)

type ts = t list

let rec parse bs acc =
  bitmatch bs with
  | { 0:8 } -> 
      acc
  | { 1:8; tl:-1:bitstring } -> 
      parse tl acc
  | { 2:8; 4:8; mss:16; tl:-1:bitstring } ->
      parse tl (MSS mss :: acc)
  | { 3:8; 3:8; shift:8; tl:-1:bitstring } ->
      parse tl (Window_size_shift shift :: acc)
  | { 4:8; 2:8; tl:-1:bitstring } ->
      parse tl (SACK_ok :: acc)
  | { 5:8; len:8; sack:len-2:bitstring; tl:-1:bitstring } ->
      let num = (len - 2) / 8 in
      let rec to_int32_list bs acc = function
      |0 -> acc
      |n ->
        bitmatch bs with 
        | { le:32; re:32; rest:-1:bitstring } ->
          to_int32_list rest ((le,re) :: acc) (n-1)
      in
      let sacks = to_int32_list sack [] num in
      parse tl (SACK sacks :: acc)
  | { 8:8; 10:8; tsval:32; tsecr:32; tl:-1:bitstring } ->
      parse tl (Timestamp (tsval,tsecr) :: acc)
  | { kind:8; len:8; pkt:len-2:string; tl:-1:bitstring } ->
      parse tl (Unknown (kind,pkt) :: acc)
  | { _ } -> acc

let marshal ts = 
  let tlen = ref 0 in
  let opts = List.rev_map (function
    |MSS sz ->
       tlen := !tlen + 4;
       (BITSTRING { 2:8; 4:8; sz:16 })
    |Window_size_shift shift ->
       tlen := !tlen + 3;
       (BITSTRING { 3:8; 3:8; shift:8 })
    |SACK_ok ->
       tlen := !tlen + 2;
       (BITSTRING { 4:8; 2:8 })
    |SACK acks ->
       let edges = Bitstring.concat (
         List.map (fun (le,re) -> BITSTRING { le:32; re:32 }) acks) in
       let len = List.length acks * 8 + 2 in
       tlen := !tlen + len;
       (BITSTRING { 5:8; len:8; edges:-1:bitstring })
    |Timestamp (tsval,tsecr) ->
       tlen := !tlen + 10;
       (BITSTRING { 8:8; 10:8; tsval:32; tsecr:32 })
    |Unknown (kind,contents) ->
       let len = String.length contents + 2 in
       tlen := !tlen + len;
       (BITSTRING { kind:8; len:8; contents:-1:string })
  ) ts in
  let padlen = 32 - (!tlen mod 32) in
  let eopt = BITSTRING { 0L:padlen } in
  Bitstring.concat (List.rev (eopt :: opts))

let of_packet bs =
  parse bs []

let to_string = function
  |MSS m -> Printf.sprintf "MSS=%d" m
  |Window_size_shift b -> Printf.sprintf "Window>>%d" b
  |SACK_ok -> "SACK_ok"
  |SACK x -> Printf.(sprintf "SACK=(%s)" (String.concat ","
    (List.map (fun (l,r) -> sprintf "%lu,%lu" l r) x)))
  |Timestamp (a,b) -> Printf.sprintf "Timestamp(%lu,%lu)" a b
  |Unknown (t,_) -> Printf.sprintf "%d?" t

let prettyprint s =
  Printf.sprintf "[ %s ]" (String.concat "; " (List.map to_string s))
