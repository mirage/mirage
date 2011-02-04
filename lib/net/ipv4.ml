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
open Nettypes

type 'a ip_output = OS.Istring.View.t -> ttl:int -> dest:int32 ->
    options:('a OS.Istring.View.data) -> Mpl.Ipv4.o

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
  netif: Netif.t;
  arp: Arp.t;
  thread: unit Lwt.t;
  mutable ip: ipv4_addr;
  mutable netmask: ipv4_addr;
  mutable gateways: ipv4_addr list;
  mutable udp: (Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t);
  mutable tcp: (Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t);
  mutable icmp: (Mpl.Ipv4.o -> Mpl.Icmp.o -> unit Lwt.t);
}

let output_broadcast t ip =
  let etherfn = Mpl.Ethernet.IPv4.t
    ~dest_mac:(`Str (ethernet_mac_to_bytes ethernet_mac_broadcast))
    ~src_mac:(`Str (ethernet_mac_to_bytes (Netif.mac t.netif)))
    ~data:(`Sub ip) in
  Netif.output t.netif (`IPv4 (Mpl.Ethernet.IPv4.m etherfn))

let is_local t ip =
  let ipand a b = Int32.logand (ipv4_addr_to_uint32 a) (ipv4_addr_to_uint32 b) in
  (ipand t.ip t.netmask) = (ipand ip t.netmask)

let classify_ip t = function
  | ip when ip = ipv4_broadcast -> Broadcast
  | ip when ip = ipv4_blank -> Broadcast
  | ip when is_local t ip -> Local
  | ip -> Gateway

let output t ~dest_ip (ip:'a ip_output) =
  (* Query ARP for destination MAC address to send this to *)
  lwt dest_mac = match classify_ip t dest_ip with
  | Broadcast -> return ethernet_mac_broadcast
  | Local -> Arp.query t.arp dest_ip
  | Gateway -> begin
      match t.gateways with 
      | hd :: _ -> Arp.query t.arp hd
      | [] -> 
          printf "IP.output: no route to %s\n%!" (ipv4_addr_to_string dest_ip);
          fail (No_route_to_destination_address dest_ip)
    end in
  let ipfn env = 
    let ttl = 38 in (* TODO ttl tracking *)
    let p = ip ~ttl ~dest:(ipv4_addr_to_uint32 dest_ip) ~options:`None env in
    let csum = OS.Istring.View.ones_complement_checksum p#env p#header_end 0l in
    p#set_checksum csum;
  in
  let etherfn = Mpl.Ethernet.IPv4.t
    ~dest_mac:(`Str (ethernet_mac_to_bytes dest_mac))
    ~src_mac:(`Str (ethernet_mac_to_bytes (Netif.mac t.netif)))
    ~data:(`Sub ipfn) in
  Netif.output t.netif (`IPv4 (Mpl.Ethernet.IPv4.m etherfn))

let input t (ip:Mpl.Ipv4.o) =
  match ip#protocol with
  |`UDP -> t.udp ip (Mpl.Udp.unmarshal ip#data_sub_view)
  |`TCP -> t.tcp ip (Mpl.Tcp.unmarshal ip#data_sub_view)
  |`ICMP -> t.icmp ip (Mpl.Icmp.unmarshal ip#data_sub_view)
  |`IGMP |`Unknown _ -> return ()

let create id = 
  lwt (netif, netif_t) = Netif.create id in
  let arp, arp_t = Arp.create netif in
  let thread,_ = Lwt.task () in
  let udp = (fun _ _ -> return (print_endline "dropped udp")) in
  let tcp = (fun _ _ -> return (print_endline "dropped tcp")) in
  let icmp = (fun _ _ -> return (print_endline "dropped icmp")) in
  let ip = ipv4_blank in
  let netmask = ipv4_blank in
  let gateways = [] in
  let t = { netif; arp; thread; udp; tcp; icmp; ip; netmask; gateways } in
  Netif.attach t.netif (`IPv4 (input t));
  let th = join [netif_t; arp_t; thread ] in
  return (t, th)

let set_ip t ip = 
  t.ip <- ip;
  (* Inform ARP layer of new IP *)
  Arp.set_bound_ips t.arp [ip]

let get_ip t = t.ip

let set_netmask t netmask =
  t.netmask <- netmask;
  return ()

let set_gateways t gateways =
  t.gateways <- gateways;
  return ()

let mac t = Netif.mac t.netif

let attach t = function
  |`UDP f -> t.udp <- f
  |`TCP f -> t.tcp <- f
  |`ICMP f -> t.icmp <- f

let detach t = function
  |`UDP -> t.udp <- (fun _ _ -> return ())
  |`TCP -> t.tcp <- (fun _ _ -> return ())
  |`ICMP -> t.icmp <- (fun _ _ -> return ())

