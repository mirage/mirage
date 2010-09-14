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

open Mlnet.Types
module M = Mpl.Mpl_stdlib

let ones_checksum sum =
    0xffff - ((sum lsr 16) + (sum land 0xffff))

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
    addsum (M.Mpl_uint16.(to_int (unmarshal env)))
  done;
  if len mod 2 = 1 then
    addsum (M.Mpl_byte.(to_int (unmarshal env) lsl 8));
  let csum = match ones_checksum !sum with
    | 0 -> 0xffff
    | n -> n in
  csum
