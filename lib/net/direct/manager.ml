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
  icmp: Icmp.t;
  udp: Udp.t;
  tcp: Tcp.Pcb.t;
}

type t = (i * unit Lwt.t) list

(* Configure an interface based on the Config module *)
let configure id t =
  match Config.t id with
  |`DHCP ->
      Printf.printf "Manager: VIF %s to DHCP\n%!" (OS.Ethif.string_of_id id);
      lwt t, th = Dhcp.Client.create t.ipv4 t.udp in
      Printf.printf "Manager: DHCP done\n%!";
      return th
  |`IPv4 (addr, netmask, gateways) ->
      OS.Console.log (Printf.sprintf "Manager: VIF %s to %s nm %s gw [%s]"
        (OS.Ethif.string_of_id id) (ipv4_addr_to_string addr) (ipv4_addr_to_string netmask)
        (String.concat ", " (List.map ipv4_addr_to_string gateways)));
      Ipv4.set_ip t.ipv4 addr >>
      Ipv4.set_netmask t.ipv4 netmask >>
      Ipv4.set_gateways t.ipv4 gateways >>
      let th, _ = Lwt.task () in
      return th (* Never return from this thread *)

(* Enumerate interfaces and manage the protocol threads *)
let create () =
  lwt ids = OS.Ethif.enumerate () in
  let wrap t = try_lwt t >>= return with
    exn -> (OS.Console.log ("Manager: exn=" ^ (Printexc.to_string exn)); fail exn) in
  lwt t = Lwt_list.map_p (fun id ->
    lwt vif = OS.Ethif.create id in
    let (netif, netif_t) = Netif.create vif in
    let (ipv4, ipv4_t) = Ipv4.create netif in
    let (icmp, icmp_t) = Icmp.create ipv4 in
    let (tcp, tcp_t) = Tcp.Pcb.create ipv4 in
    let (udp, udp_t) = Udp.create ipv4 in
    let t = { ipv4; tcp; udp; icmp; netif } in
    lwt config_t = configure id t in
    let th = pick [wrap udp_t; wrap tcp_t; wrap ipv4_t; wrap netif_t;
      wrap icmp_t; wrap config_t] in
    return (t, th)
  ) ids in
  let th,_ = Lwt.task () in
  Lwt.on_cancel th (fun _ -> List.iter (fun (_,th) -> Lwt.cancel th) t);
  return (t, th)

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

(* TODO: do actual route selection *)
let udpv4_of_addr (t:t) addr =
  lwt i,_ = i_of_ip t addr in
  return i.udp
