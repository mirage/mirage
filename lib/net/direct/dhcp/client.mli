(*
 * Copyright (c) 2006-2011 Anil Madhavapeddy <anil@recoil.org>
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

type offer = {
  ip_addr : Nettypes.ipv4_addr;
  netmask : Nettypes.ipv4_addr option;
  gateways : Nettypes.ipv4_addr list;
  dns : Nettypes.ipv4_addr list;
  lease : int32;
  xid : int32;
}

type state =
    Disabled
  | Request_sent of int32
  | Offer_accepted of offer
  | Lease_held of offer
  | Shutting_down

type t

val input : t -> src:'a -> dst:'b -> source_port:'c -> Bitstring.t -> unit Lwt.t
val create : Ipv4.t -> Udp.t -> (t * unit Lwt.t) Lwt.t
