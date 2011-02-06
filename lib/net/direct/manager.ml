(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

(* The manager process binds application ports to interfaces, and
   will eventually deal with load balancing and route determination
   (e.g. if a remote target is on the same host, swap to shared memory *)

open Lwt
open Nettypes

exception Error of string

type i = {
  netif: Netif.t;
  ipv4: Ipv4.t;
  udp: Udp.t;
  tcp: Tcp.Pcb.t;
}

type t = (i * unit Lwt.t) list

(* Enumerate interfaces and manage the protocol threads *)
let create () : t Lwt.t =
  lwt ids = OS.Ethif.enumerate () in
  Lwt_list.map_p (fun id ->
    lwt vif = OS.Ethif.create id in
    let (netif, netif_t) = Netif.create vif in
    let (ipv4, ipv4_t) = Ipv4.create netif in
    let (tcp, tcp_t) = Tcp.Pcb.create ipv4 in
    let (udp, udp_t) = Udp.create ipv4 in
    let th = pick [udp_t; tcp_t; ipv4_t; netif_t] in
    let t = { ipv4; tcp; udp; netif } in
    return (t, th)
  ) ids
  
let destroy t =
  List.iter (fun (_,th) -> Lwt.cancel th) t

(* Find the interface associated with the address *)
let i_of_ip t addr =
  try
    (match addr with
     |None -> return (List.hd t) (* TODO: bind to all interfaces *)
     |Some addr -> return (List.find (fun (i,_) -> Ipv4.get_ip i.ipv4 = addr) t)
    )
  with _ -> fail (Error "No interface found for IP")

(* Match an address and port to a TCP thread *)
let tcpv4_of_addr (t:t) addr =
  lwt i,_ = i_of_ip t addr in
  return i.tcp
