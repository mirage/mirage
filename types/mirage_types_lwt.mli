(*
 * Copyright (c) 2011-2014 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2013-2014 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2014 Citrix Systems Inc
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

(** lwt-compatible MirageOS signatures.

    {e Release %%VERSION%% } *)

module type TIME = Mirage_time_lwt.S
module type MCLOCK = Mirage_clock_lwt.MCLOCK
module type PCLOCK = Mirage_clock_lwt.PCLOCK

module type RANDOM = Mirage_random.C
module type FLOW = Mirage_flow_lwt.S

(** Consoles *)
module type CONSOLE = Mirage_console_lwt.S

(** Block devices *)
module type BLOCK = Mirage_block_lwt.S

(** Network *)
module type NETWORK = Mirage_net_lwt.S

(** Network protocol implementations from Mirage_protocols *)
module type ETHIF = Mirage_protocols_lwt.ETHIF
module type ARP = Mirage_protocols_lwt.ARP
module type IP = Mirage_protocols_lwt.IP
module type IPV4 = Mirage_protocols_lwt.IPV4
module type IPV6 = Mirage_protocols_lwt.IPV6
module type ICMP = Mirage_protocols_lwt.ICMP
module type ICMPV4 = Mirage_protocols_lwt.ICMPV4
module type UDP = Mirage_protocols_lwt.UDP
module type UDPV4 = Mirage_protocols_lwt.UDPV4
module type UDPV6 = Mirage_protocols_lwt.UDPV6
module type TCP = Mirage_protocols_lwt.TCP
module type TCPV4 = Mirage_protocols_lwt.TCPV4
module type TCPV6 = Mirage_protocols_lwt.TCPV6

(** Buffered TCP channel *)
module type CHANNEL = Mirage_channel_lwt.S

(** KV RO *)
module type KV_RO = Mirage_kv_lwt.RO

(** FS *)
module type FS = Mirage_fs_lwt.S

(** Single network stack *)
module type STACKV4 = Mirage_stack_lwt.V4
