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

open Nettypes

type 'a ip_output = OS.Istring.t -> ttl:int -> dest:int32 ->
  options:('a OS.Istring.View.data) -> Mpl.Ipv4.o

type t
val output: t -> dest_ip:ipv4_addr -> 'a ip_output -> Mpl.Ethernet.o Lwt.t
val set_ip: t -> ipv4_addr -> unit Lwt.t
val get_ip: t -> ipv4_addr
val mac: t -> ethernet_mac
val set_netmask: t -> ipv4_addr -> unit Lwt.t
val set_gateways: t -> ipv4_addr list -> unit Lwt.t
val attach: t -> 
    [  `UDP of Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t
     | `TCP of Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t
     | `ICMP of Mpl.Ipv4.o -> Mpl.Icmp.o -> unit Lwt.t
    ] -> unit
val detach: t -> [ `UDP | `TCP | `ICMP ] -> unit
val create : Netif.t -> t * unit Lwt.t
