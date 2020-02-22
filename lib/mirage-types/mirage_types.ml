(*
 * Copyright (c) 2011-2015 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2013-2015 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013      Citrix Systems Inc
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

(** MirageOS Signatures.

    This module defines the basic signatures that functor parameters should
    implement in MirageOS to be portable.

    {2 General conventions}

    - errors which application programmers are expected to handle (e.g.
      connection refused or end of file) are encoded as result types where
      [Ok x] means the operation was succesful and returns [x] and where
      [Error e] means the operation has failed with error [e]. The error [e]
      uses the {!Rresult.R.msg} type for the most general error message, and
      possibly more specific ones depending on the interface.
    - errors which represent programming errors such as assertion failures or
      illegal arguments are encoded as exceptions. The application may attempt
      to catch exceptions and recover or simply let the exception propagate and
      crash the application. If the application crashes then the runtime system
      should output diagnostics and abort.
    - operations which perform I/O return values of [type +'a io] which allow
      the application to either wait for the I/O to be completed or leave it
      running asynchronously. If the I/O completes with an error then the
      operation may have completely failed, partially succeeded or even
      completely succeeded (e.g. it may only be a confirmation message in a
      network protocol which was missed): see individual API descriptions for
      details.

    {e Release %%VERSION%%} *)

module type DEVICE = Mirage_device.S
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_device.S."]

(** {2 Time and clock devices} *)

module type TIME = Mirage_time.S
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_time.S."]

module type MCLOCK = Mirage_clock.MCLOCK
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_clock.MCLOCK."]

module type PCLOCK = Mirage_clock.PCLOCK
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_clock.PCLOCK."]

module type RANDOM = Mirage_random.S
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_random.S."]
(** {2 Random}

    Operations to generate random numbers. *)

(** {2 Connection between endpoints} *)

module type FLOW = Mirage_flow.S
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_flow.S."]

(** {2 Console} *)

module type CONSOLE = Mirage_console.S
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_console.S."]

(** {2 Sector-addressible block devices} *)

module type BLOCK = Mirage_block.S
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_block.S."]

module type NETWORK = Mirage_net.S
[@@ocaml.deprecated "This will be removed from MirageOS 4.0, use Mirage_net.S."]
(** {2 Network module} *)

module type ETHERNET = Mirage_protocols.ETHERNET
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.ETHERNET."]
(** {2 Ethernet layer} *)

module type IP = Mirage_protocols.IP
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.IP."]
(** {2 IP stack}

    An IP module that allows communication via IPv4 or IPv6. *)

module type ARP = Mirage_protocols.ARP
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.ARP."]
(** {2 ARP}

    A module that allows communication via Address Resolution Protocol. *)

module type IPV4 = Mirage_protocols.IPV4
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.IPV4."]
(** {2 IPv4 stack} *)

module type IPV6 = Mirage_protocols.IPV6
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.IPV6."]
(** {2 IPv6 stack} *)

module type ICMP = Mirage_protocols.ICMP
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.ICMP."]
(** {2 ICMP module} *)

module type ICMPV4 = Mirage_protocols.ICMPV4
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.ICMPV4."]

module type UDP = Mirage_protocols.UDP
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.UDP."]
(** {2 UDP module}

    A UDP module that can send and receive datagrams. *)

module type UDPV4 = Mirage_protocols.UDPV4
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.UDPV4."]

module type UDPV6 = Mirage_protocols.UDPV6
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.UDPV6."]

module type TCP = Mirage_protocols.TCP
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.TCP."]
(** {2 TCP module}

    A TCP module that can send and receive reliable flows using the TCP
    protocol. *)

module type TCPV4 = Mirage_protocols.TCPV4
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.TCPV4."]

module type TCPV6 = Mirage_protocols.TCPV6
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_protocols.TCPV6."]

module type STACKV4 = Mirage_stack.V4
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_stack.V4."]
(** {2 TCP/IPv4 stack}

    A complete TCP/IP stack that can be used by applications to receive and
    transmit network traffic. *)

module type CHANNEL = Mirage_channel.S
[@@ocaml.deprecated
  "This will be removed from MirageOS 4.0, use Mirage_channel.S."]
(** {2 Buffered byte-stream} *)

(** {2 Static Key/value store} *)

module type KV_RO = Mirage_kv.RO
[@@ocaml.deprecated "This will be removed from MirageOS 4.0, use Mirage_kv.RO."]

module type KV_RW = Mirage_kv.RW
[@@ocaml.deprecated "This will be removed from MirageOS 4.0, use Mirage_kv.RW."]

(** {2 Filesystem devices} *)

module type FS = Mirage_fs.S [@ocaml.warning "-3"]
[@@ocaml.deprecated "This will be removed from MirageOS 4.0, use Mirage_kv.RW."]
