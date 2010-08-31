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

module type UP = sig
  type t
  val output: t -> dest_ip:ipv4_addr -> (Mpl.Mpl_stdlib.env -> Mpl.Ipv4.o) -> unit Lwt.t
  val set_ip: t -> ipv4_addr -> unit Lwt.t
  val get_ip: t -> ipv4_addr
  val mac: t -> ethernet_mac
  val set_netmask: t -> ipv4_addr -> unit Lwt.t
  val set_gateways: t -> ipv4_addr list -> unit Lwt.t
  val attach: t -> 
    [  `UDP of Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t
     | `ICMP of Mpl.Ipv4.o -> Mpl.Icmp.o -> unit Lwt.t
    ] -> unit
end

module IPv4 (IF:Ethif.UP)
            (ARP:Arp.UP with type id=IF.id and type ethif=IF.t)
            = struct

  type state =
  |Obtaining_ip
  |Up
  |Down
  |Shutting_down

  type classify =
  |Broadcast
  |Gateway
  |Local

  exception No_route_to_destination_address of ipv4_addr

  type t = {
    ethif: IF.t;
    arp: ARP.t;
    thread: unit Lwt.t;
    mutable ip: ipv4_addr;
    mutable netmask: ipv4_addr;
    mutable gateways: ipv4_addr list;
    mutable udp: (Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t);
    mutable icmp: (Mpl.Ipv4.o -> Mpl.Icmp.o -> unit Lwt.t);
  }

  let output_broadcast t ip =
    let etherfn = Mpl.Ethernet.IPv4.t
      ~dest_mac:(`Str (ethernet_mac_to_bytes ethernet_mac_broadcast))
      ~src_mac:(`Str (ethernet_mac_to_bytes (IF.mac t.ethif)))
      ~data:(`Sub ip) in
    IF.output t.ethif (`IPv4 (Mpl.Ethernet.IPv4.m etherfn))

  let is_local t ip =
    let ipand a b = Int32.logand (ipv4_addr_to_uint32 a) (ipv4_addr_to_uint32 b) in
    (ipand t.ip t.netmask) = (ipand ip t.netmask)

  let classify_ip t = function
    | ip when ip = ipv4_broadcast -> Broadcast
    | ip when ip = ipv4_blank -> Broadcast
    | ip when is_local t ip -> Local
    | ip -> Gateway

  let output t ~dest_ip ip =
    (* Query ARP for destination MAC address to send this to *)
    lwt dest_mac = match classify_ip t dest_ip with
    | Broadcast -> return ethernet_mac_broadcast
    | Local -> ARP.query t.arp dest_ip
    | Gateway -> begin
        match t.gateways with 
        | hd :: _ -> ARP.query t.arp hd
        | [] -> fail (No_route_to_destination_address dest_ip)
      end in
    let ipfn env = 
      let p = ip env in
      let csum = Checksum.ip_checksum (p#header_end / 4)
        (Mpl.Mpl_stdlib.env_pos env 0) in
      p#set_checksum csum;
    in
    let etherfn = Mpl.Ethernet.IPv4.t
      ~dest_mac:(`Str (ethernet_mac_to_bytes dest_mac))
      ~src_mac:(`Str (ethernet_mac_to_bytes (IF.mac t.ethif)))
      ~data:(`Sub ipfn) in
    IF.output t.ethif (`IPv4 (Mpl.Ethernet.IPv4.m etherfn))

  let input t (ip:Mpl.Ipv4.o) =
    match ip#protocol with
    |`UDP -> t.udp ip (Mpl.Udp.unmarshal ip#data_env)
    |`TCP -> return ()
    |`ICMP -> t.icmp ip (Mpl.Icmp.unmarshal ip#data_env)
    |`IGMP |`Unknown _ -> return ()

  let create id = 
    lwt (ethif, ethif_t) = IF.create id in
    let arp, arp_t = ARP.create ethif in
    let thread,_ = Lwt.task () in
    let udp = (fun _ _ -> return (print_endline "dropped udp")) in
    let icmp = (fun _ _ -> return (print_endline "dropped icmp")) in
    let ip = ipv4_blank in
    let netmask = ipv4_blank in
    let gateways = [] in
    let t = { ethif; arp; thread; udp; icmp; ip; netmask; gateways } in
    IF.attach t.ethif (`IPv4 (input t));
    let th = join [ethif_t; arp_t; thread ] in
    return (t, th)

  let set_ip t ip = 
    t.ip <- ip;
    (* Inform ARP layer of new IP *)
    ARP.set_bound_ips t.arp [ip]

  let get_ip t = t.ip

  let set_netmask t netmask =
    t.netmask <- netmask;
    return ()

  let set_gateways t gateways =
    t.gateways <- gateways;
    return ()

  let mac t = IF.mac t.ethif

  let attach t = function
    |`UDP f -> t.udp <- f
    |`ICMP f -> t.icmp <- f
end
