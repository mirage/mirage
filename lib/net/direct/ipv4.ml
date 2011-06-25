(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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

type classify =
  |Broadcast
  |Gateway
  |Local

exception No_route_to_destination_address of ipv4_addr

type t = {
  ethif: Ethif.t;
  mutable ip: ipv4_addr;
  mutable netmask: ipv4_addr;
  mutable gateways: ipv4_addr list;
}

(*let output_broadcast t ip =
  let etherfn = Mpl.Ethernet.IPv4.t
    ~dest_mac:(`Str (ethernet_mac_to_bytes ethernet_mac_broadcast))
    ~src_mac:(`Str (ethernet_mac_to_bytes (Ethif.mac t.netif)))
    ~data:(`Sub ip) in
  Ethif.output t.netif (`IPv4 (Mpl.Ethernet.IPv4.m etherfn))
*)

(* XXX should optimise this! *)
let is_local t ip =
  let ipand a b = Int32.logand (ipv4_addr_to_uint32 a) (ipv4_addr_to_uint32 b) in
  (ipand t.ip t.netmask) = (ipand ip t.netmask)

let classify_ip t = function
  | ip when ip = ipv4_broadcast -> Broadcast
  | ip when ip = ipv4_blank -> Broadcast
  | ip when is_local t ip -> Local
  | ip -> Gateway

let destination_mac t = function
  | ip when ip = ipv4_broadcast || ip = ipv4_blank -> (* Broadcast *)
      return ethernet_mac_broadcast
  | ip when is_local t ip -> (* Local *)
      Ethif.query_arp t.ethif ip
  | ip -> begin (* Gateway *)
      match t.gateways with 
      | hd :: _ -> Ethif.query_arp t.ethif hd
      | [] -> 
          printf "IP.output: no route to %s\n%!" (ipv4_addr_to_string ip);
          fail (No_route_to_destination_address ip)
    end

(* 
let output t ~dest_ip pkt =
 let ipfn env = 
    let ttl = 38 in (* TODO ttl tracking *)
    let p = ip ~ttl ~dest:(ipv4_addr_to_uint32 dest_ip) ~options:`None env in
    let csum = OS.Istring.ones_complement_checksum (Mpl.Ipv4.env p) (Mpl.Ipv4.header_end p) 0l in
    Mpl.Ipv4.set_checksum p csum;
  in
  let etherfn = Mpl.Ethernet.IPv4.t
    ~dest_mac:(`Str (ethernet_mac_to_bytes dest_mac))
    ~src_mac:(`Str (ethernet_mac_to_bytes (Ethif.mac t.netif)))
    ~data:(`Sub ipfn) in
  Ethif.output t.netif (`IPv4 (Mpl.Ethernet.IPv4.m etherfn))
*)

let input t pkt =
  bitmatch pkt with
  |{4:4; ihl:4; tos:8; tlen:16; ipid:16; flags:3; fragoff:13;
    ttl:8; proto:8; checksum:16; src:32; dst:32;
    options:(ihl-5)*32:bitstring; data:-1:bitstring } ->
      printf "Packet: proto=%d src=%ld dst=%ld\n%!" proto src dst;
      return ()
  |{_} ->
      return (printf "IPv4: not an IP packet, discarding\n%!")
 
let create ethif = 
  let ip = ipv4_blank in
  let netmask = ipv4_blank in
  let gateways = [] in
  { ethif; ip; netmask; gateways }

let set_ip t ip = 
  t.ip <- ip;
  (* Inform ARP layer of new IP *)
  Ethif.add_ip t.ethif ip

let get_ip t = t.ip

let set_netmask t netmask =
  t.netmask <- netmask;
  return ()

let set_gateways t gateways =
  t.gateways <- gateways;
  return ()

let mac t = Ethif.mac t.ethif

