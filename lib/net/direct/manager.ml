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

type id = OS.Netif.id

type interface = {
  id: id;
  netif: Ethif.t;
  ipv4: Ipv4.t;
  icmp: Icmp.t;
  udp: Udp.t;
  tcp: Tcp.Pcb.t;
}

type interface_t = interface * unit Lwt.t

type t = {
  listener: t -> interface -> id -> unit Lwt.t;
  listeners: (id, interface_t) Hashtbl.t;
}

type config = [ `DHCP | `IPv4 of ipv4_addr * ipv4_addr * ipv4_addr list ]

(* Configure an interface based on the Config module *)
let configure i =
  function
  |`DHCP ->
    Printf.printf "Manager: VIF %s to DHCP\n%!" (OS.Netif.string_of_id i.id);
    lwt t, th = Dhcp.Client.create i.ipv4 i.udp in
    Printf.printf "Manager: DHCP done\n%!";
    th >>
    return ()
  |`IPv4 (addr, netmask, gateways) ->
    Printf.sprintf "Manager: VIF %s to %s nm %s gw [%s]"
      (OS.Netif.string_of_id i.id) (ipv4_addr_to_string addr) (ipv4_addr_to_string netmask)
      (String.concat ", " (List.map ipv4_addr_to_string gateways));
    Ipv4.set_ip i.ipv4 addr >>
    Ipv4.set_netmask i.ipv4 netmask >>
    Ipv4.set_gateways i.ipv4 gateways >>
    return ()

(* Plug in a new network interface with given id *)
let plug t id = 
  let wrap (s,t) = try_lwt t >>= return with exn ->
    (Printf.printf "Manager: exn=%s %s\n%!" s (Printexc.to_string exn); fail exn) in
  lwt vif = OS.Netif.create id in
  let (netif, netif_t) = Ethif.create vif in
  let (ipv4, ipv4_t) = Ipv4.create netif in
  let (icmp, icmp_t) = Icmp.create ipv4 in
  let (tcp, tcp_t) = Tcp.Pcb.create ipv4 in
  let (udp, udp_t) = Udp.create ipv4 in
  let i = { id; ipv4; tcp; udp; icmp; netif } in
  (* The interface thread can be cancelled by exceptions from the
     rest of the threads, as a debug measure.
     TODO: think about restart strategies here *)
  let th = join (List.map wrap ["udp",udp_t; "tcp",tcp_t; "ipv4",ipv4_t;
    "netif", netif_t; "icmp", icmp_t]) in
  (* Register the interface_t with the manager interface *)
  Hashtbl.add t.listeners id (i,th);
  t.listener t i id

(* Unplug a network interface and cancel all its threads. *)
let unplug t id =
  try
    let i, th = Hashtbl.find t.listeners id in
    Lwt.cancel th;
    Hashtbl.remove t.listeners id
  with Not_found -> ()

(* Enumerate interfaces and manage the protocol threads.
   The listener becomes a new thread that is spawned when a 
   new interface shows up. *)
let create listener =
  let listeners = Hashtbl.create 1 in
  let t = { listener; listeners } in
  lwt ids = OS.Netif.enumerate () in
  Lwt_list.iter_s (plug t) ids >>
  let th,_ = Lwt.task () in
  Lwt.on_cancel th (fun _ -> Hashtbl.iter (fun id _ -> unplug t id) listeners);
  th

(* Find the interfaces associated with the address *)
let i_of_ip t addr =
  match addr with
  |None ->
    Hashtbl.fold (fun _ (i,_) a ->
      i :: a) t.listeners []
  |Some addr -> begin
    Hashtbl.fold (fun _ (i,_) a ->
      if Ipv4.get_ip i.ipv4 = addr then i :: a else a
    ) t.listeners [];
  end

(* Match an address and port to a TCP thread *)
let tcpv4_of_addr t addr =
  List.map (fun x -> x.tcp) (i_of_ip t addr)

(* TODO: do actual route selection *)
let udpv4_of_addr (t:t) addr =
  List.map (fun x -> x.udp) (i_of_ip t addr)
