(*
 * Copyright (c) 2005 Anil Madhavapeddy <anil@recoil.org>
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
 *
 *)

open Nettypes

let ones_checksum sum =
  0xffff - ((sum lsr 16) + (sum land 0xffff))

(* TODO: coalesce bounds checking as MPL.dissect used to -avsm *)
let ip sz env =
  let env = OS.Istring.View.copy env in
  let sum = ref 0 in
  for i = 1 to sz do
    let x = OS.Istring.View.unmarshal_uint16_be env in
    let y = OS.Istring.View.unmarshal_uint16_be env in
    let y = if i = 3 then 0 else y in (* zero out checksum header *)
    sum := !sum + x + y;
  done;
  ones_checksum !sum

(* TODO: coalesce bounds checking as MPL.dissect used to -avsm *)
let icmp env =
  let env = OS.Istring.View.copy env in
  let sum = ref 0 in
  let sz = OS.Istring.View.length env / 4 in
  for i = 1 to sz do
    let x = OS.Istring.View.unmarshal_uint16_be env in
    let y = OS.Istring.View.unmarshal_uint16_be env in
    let y = if i = 1 then 0 else y in (* zero out checksum header *)
    sum := !sum + x + y;
  done;
  ones_checksum !sum

(* TODO: coalesce bounds checking as MPL.dissect used to -avsm *)
let udp ip_src ip_dest (udp:Mpl.Udp.o)  =
  let sum = ref 0 in
  let addsum x = sum := !sum + x in
  let add32 x = addsum (Int32.to_int (Int32.shift_right x 16));
    addsum (Int32.to_int (Int32.logand x 65535l)) in
  (* pseudo header *)
  add32 (ipv4_addr_to_uint32 ip_src);
  add32 (ipv4_addr_to_uint32 ip_dest);
  addsum 17; (* UDP protocol number *)
  let len = udp#sizeof in
  addsum len;
  (* udp packet *)
  let env = udp#env in
  for i = 1 to len / 2 do
    addsum (OS.Istring.View.unmarshal_uint16_be env)
  done;
  if len mod 2 = 1 then
    addsum (OS.Istring.View.unmarshal_byte env lsl 8);
  let csum = match ones_checksum !sum with
    | 0 -> 0xffff
    | n -> n in
  csum

let tcp ip_src ip_dest (tcp:Mpl.Tcp.o) =
  let sum = ref 0 in
  let addsum x = sum := !sum + x in
  let add32 x = addsum (Int32.to_int (Int32.shift_right x 16));
    addsum (Int32.to_int (Int32.logand x 65535l)) in
  (* pseudo header *)
  add32 (ipv4_addr_to_uint32 ip_src);
  add32 (ipv4_addr_to_uint32 ip_dest);
  addsum 6;
  let len = tcp#sizeof in
  addsum len;
  let env = tcp#env in
  for i = 1 to len / 2 do
    addsum (OS.Istring.View.unmarshal_uint16_be env);
  done;
  if len mod 2 = 1 then
    addsum (OS.Istring.View.unmarshal_byte env lsl 8);
  let csum = ones_checksum !sum in
  csum
