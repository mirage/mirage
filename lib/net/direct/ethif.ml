(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2011 Richard Mortier <richard.mortier@nottingham.ac.uk>
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
open Nettypes
open Printf

type frame = {
  dmac: ethernet_mac;
  smac: ethernet_mac;
}

type t = {
  ethif: OS.Netif.t;
  mac: ethernet_mac;
  arp: Arp.t;
  mutable ipv4: (Bitstring.t -> unit Lwt.t);
  mutable raw_eth: (string -> string * int * int -> unit Lwt.t) list;
}

let gen_frame dmac smac =
  let dmac = ethernet_mac_of_bytes dmac in
  let smac = ethernet_mac_of_bytes smac in
  { dmac; smac; }

(* Handle a single input frame *)
let input t frame =
(*  let _ = (printf "Packet received dev (%s) \n" ( OS.Netif.ethid t.ethif )) in *)
  bitmatch frame with
  |{dmac:48:string; smac:48:string;
    0x0806:16;     (* ethertype *)
    1:16;          (* htype const 1 *)
    0x0800:16;     (* ptype const, ND used for IPv6 now *)
    6:8;           (* hlen const 6 *)
    4:8;           (* plen const, ND used for IPv6 now *)
    op:16;
    sha:48:string; spa:32;
    tha:48:string; tpa:32 } ->
      let sha = ethernet_mac_of_bytes sha in
      let spa = ipv4_addr_of_uint32 spa in
      let tha = ethernet_mac_of_bytes tha in
      let tpa = ipv4_addr_of_uint32 tpa in
      let op = match op with |1->`Request |2 -> `Reply |n -> `Unknown n in
      let arp = { op; sha; spa; tha; tpa } in
      Arp.input t.arp arp

  |{dmac:48:string; smac:48:string;
    etype:16; bits:-1:bitstring } -> 
      (* let _ = gen_frame dmac smac in *)
      begin match etype with
      | 0x0800 (* IPv4 *) -> t.ipv4 bits
      | 0x86dd (* IPv6 *) -> return (printf "Ethif: discarding ipv6\n%!")
      | etype -> return (printf "Ethif: unknown frame %x\n%!" etype)
      end
  |{_} ->
      return (printf "Ethif: dropping input\n%!")

(* Loop and listen for frames *)
let rec listen t =
  OS.Netif.listen t.ethif (input t)

let output t frame =
  OS.Netif.output t.ethif frame

let output_arp ethif arp =
  let dmac = ethernet_mac_to_bytes arp.tha in
  let smac = ethernet_mac_to_bytes arp.sha in
  let spa = ipv4_addr_to_uint32 arp.spa in
  let tpa = ipv4_addr_to_uint32 arp.tpa in
  let op = match arp.op with |`Request->1 |`Reply->2 |`Unknown n -> n in
  let frame = BITSTRING {
    dmac:48:string; smac:48:string;
    0x0806:16;  (* ethertype *)
    1:16;       (* htype *)
    0x0800:16;  (* ptype *)
    6:8;        (* hlen *)
    4:8;        (* plen *)
    op:16;
    smac:48:string; spa:32;
    dmac:48:string; tpa:32
  } in
  OS.Netif.output ethif [frame]

let create ethif =
  let ipv4 = (fun _ -> return ()) in
  let mac = ethernet_mac_of_bytes (OS.Netif.mac ethif) in
  let get_mac () = mac in
  let arp = Arp.create ~output:(output_arp ethif) ~get_mac in
  let t = { ethif; ipv4; mac; arp; raw_eth=[] } in
  let listen = listen t in
  (t, listen)

let input_raw t frame = 
  List.iter (fun k -> (k (OS.Netif.ethid t.ethif) frame ); () ) t.raw_eth;
  return ()

(* Loop and listen for frames *)
let rec raw_listen t =
  OS.Netif.listen t.ethif (input_raw t)

let create_raw ethif = 
  printf "creating raw socket for intf %s\n" (OS.Netif.ethid ethif); 
  let ipv4 = (fun _ -> return ()) in
  let mac = ethernet_mac_of_bytes (OS.Netif.mac ethif) in
  let get_mac () = mac in
  let arp = Arp.create ~output:(output_arp ethif) ~get_mac in
  let t = { ethif; ipv4; mac; arp; raw_eth=[] } in
  let raw_listen = raw_listen t in
  (t, raw_listen)

let intercept t fn = 
  t.raw_eth <- t.raw_eth @ [fn]

let add_ip t = Arp.add_ip t.arp
let remove_ip t = Arp.remove_ip t.arp
let query_arp t = Arp.query t.arp

let attach t = function
  |`IPv4 fn -> t.ipv4 <- fn

let detach t = function
  |`IPv4 -> t.ipv4 <- (fun _ -> return ())

let mac t = t.mac
let get_ethif t =
  t.ethif

let send_raw t frame =
  OS.Netif.output t.ethif frame
