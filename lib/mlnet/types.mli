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

type bytes = string

type ethernet_mac
val ethernet_mac_of_bytes : string -> ethernet_mac
val ethernet_mac_of_string : string -> ethernet_mac option
val ethernet_mac_to_bytes : ethernet_mac -> bytes
val ethernet_mac_to_string : ethernet_mac -> string
val ethernet_mac_broadcast: ethernet_mac

type ipv4_addr
val ipv4_addr_of_bytes : string -> ipv4_addr
val ipv4_addr_of_tuple : (int * int * int * int) -> ipv4_addr
val ipv4_addr_of_string : string -> ipv4_addr option
val ipv4_addr_to_bytes : ipv4_addr -> bytes
val ipv4_addr_to_string : ipv4_addr -> string
val ipv4_addr_of_uint32 : int32 -> ipv4_addr
val ipv4_addr_to_uint32 : ipv4_addr -> int32
val ipv4_blank : ipv4_addr
val ipv4_broadcast : ipv4_addr
val ipv4_localhost : ipv4_addr
