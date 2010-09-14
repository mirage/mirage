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
 *
 *)
open Lwt
open Types

type t
type id
val create: id -> (t * unit Lwt.t) Lwt.t
val output : t -> Mpl.Ethernet.x -> unit Lwt.t
val attach :
  t ->
    [   `ARP of Mpl.Ethernet.ARP.o -> unit Lwt.t
      | `IPv4 of Mpl.Ipv4.o -> unit Lwt.t
      | `IPv6 of Mpl.Ethernet.IPv4.o -> unit Lwt.t
    ] -> unit
val detach : t -> [`ARP |`IPv4 |`IPv6 ] -> unit
val mac : t -> ethernet_mac
