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

open Lwt
open Printf
open Mlnet_types

module type UP_conf = sig
  type t
  val output: t -> (Mpl.Ipv4.o -> unit Lwt.t) -> unit Lwt.t
  val attach: t -> 
    [  `UDP of Mpl.Udp.o -> unit Lwt.t
     | `ICMP of Mpl.Icmp.o -> unit Lwt.t
    ]
end

module IPv4 (IF:Ethif.UP)
            (ARP:Arp.UP with type id=IF.id and type ethif=IF.t) = struct

  type state =
  |Obtaining_ip
  |Up
  |Down
  |Shutting_down

  type t = {
    ethif: IF.t;
    arp: ARP.t;
    thread: unit Lwt.t;
    mutable udp: (Mpl.Udp.o -> unit Lwt.t);
(*    mutable tcp: (Mpl.Tcp.o -> unit Lwt.t); *)
    mutable icmp: (Mpl.Icmp.o -> unit Lwt.t);
  }

  let output_broadcast t ip =
    let etherfn = Mpl.Ethernet.IPv4.t
      ~dest_mac:(`Str (ethernet_mac_to_bytes ethernet_mac_broadcast))
      ~src_mac:(`Str (ethernet_mac_to_bytes (IF.mac t.ethif)))
      ~data:(`Sub ip) in
    IF.output t.ethif (`IPv4 (Mpl.Ethernet.IPv4.m etherfn))

  let output t ip =
    (* Query ARP for destination MAC address to send this to *)
    return ()

  let input t (ip:Mpl.Ipv4.o) =
    match ip#protocol with
    |`UDP -> t.udp (Mpl.Udp.unmarshal ip#data_env)
    |`TCP -> return ()
    |`ICMP -> t.icmp (Mpl.Icmp.unmarshal ip#data_env)
    |`IGMP |`Unknown _ -> return ()

  let create id = 
    lwt (ethif, ethif_t) = IF.create id in
    let arp, arp_t = ARP.create ethif in
    let thread,_ = Lwt.task () in
    let udp = (fun _ -> return (print_endline "dropped udp")) in
    let icmp = (fun _ -> return (print_endline "dropped icmp")) in
    let t = { ethif; arp; thread; udp; icmp } in
    printf "IPv4.create done\n%!";
    IF.attach t.ethif (`IPv4 (input t));
    let th = join [ethif_t; arp_t; thread ] in
    return (t, th)

  let attach t = function
    |`UDP f -> t.udp <- f
    |`ICMP f -> t.icmp <- f
end
