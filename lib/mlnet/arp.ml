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
 *
 *)

open Lwt
open Mlnet_types
open Printf

(* Interface exposed higher up the stack (usually just IPv4) *)
module type UP = sig
  type t
  type id
  type ethif
 
  val set_bound_ips: t -> ipv4_addr list -> unit Lwt.t
  val get_bound_ips: t -> ipv4_addr list
  val create: ethif -> (t * unit Lwt.t)
end

module ARP(IF: Ethif.UP) = struct

  (* TODO: ARP timeout with an Lwt_pqueue and not just a hashtable *)
  type t = {
    ethif: IF.t;
    cache: (ethernet_mac, ipv4_addr) Hashtbl.t;
    mutable bound_ips: ipv4_addr list;
    thread: unit Lwt.t;
  }

  type id = IF.id
  type ethif = IF.t

  (* Prettyprint cache contents *)
  let prettyprint t =
    printf "ARP info:\n"; 
    Hashtbl.iter (fun mac ip -> 
      printf "%s -> %s\n%!" 
        (ethernet_mac_to_string mac) 
        (ipv4_addr_to_string ip)) t.cache

  (* Transmit an ARP packet *)
  let output t arp =
    IF.output t.ethif (`ARP (Mpl.Ethernet.ARP.m arp))

  (* Input handler for an ARP packet, registered through attach() *)
  let input t (arp:Mpl.Ethernet.ARP.o) =
    match arp#ptype with
    |`IPv4 -> begin
      match arp#operation with
      |`Request ->
        (* Received ARP request, check if we can satisfy it from
           our own IPv4 list *)
        let req_ipv4 = ipv4_addr_of_bytes arp#tpa in
        if List.mem req_ipv4 t.bound_ips then begin
          (* We own this IP, so reply with our MAC *)
          let src_mac = `Str (ethernet_mac_to_bytes (IF.mac t.ethif)) in
          let dest_mac = `Str arp#src_mac in
          let spa = `Str arp#tpa in (* the requested IP *)
          let tpa = `Str arp#spa in (* the requesting host's IP *)
          output t (Mpl.Ethernet.ARP.t
            ~src_mac ~dest_mac ~ptype:`IPv4 ~operation:`Reply
            ~sha:src_mac ~spa ~tha:dest_mac ~tpa
          )
        end else return ()
      |`Reply ->
        let frm_mac = ethernet_mac_of_bytes arp#sha in
        let frm_ip = ipv4_addr_of_bytes arp#spa in
        Hashtbl.replace t.cache frm_mac frm_ip;
        prettyprint t;
        return ()
      |`Unknown _ -> return ()
    end
    |`IPv6 |`Unknown _ -> return ()

  (* Detach an ARP handler and remove the handler from the interface *)
  let destroy t = Lwt.cancel t.thread

  (* Create an ARP handler and attach it to the Ethernet interface *)
  let create ethif =
    let thread,_ = Lwt.task () in
    let t = { cache=Hashtbl.create 1; bound_ips=[]; thread; ethif } in
    Lwt.on_cancel thread (fun () -> 
      printf "ARP shutdown\n%!";
      IF.detach t.ethif `ARP);
    IF.attach t.ethif (`ARP (input t));
    printf "ARP created\n%!";
    t, thread

  (* Send a gratuitous ARP for our IP addresses *)
  let output_garp t =
    let dest_mac = `Str (ethernet_mac_to_bytes ethernet_mac_broadcast) in
    let src_mac = `Str (ethernet_mac_to_bytes (IF.mac t.ethif)) in
    Lwt_list.iter_s (fun ip ->
      let ip = `Str (ipv4_addr_to_bytes ip) in
      output t (Mpl.Ethernet.ARP.t
        ~dest_mac ~src_mac ~ptype: `IPv4 ~operation: `Reply
        ~sha: src_mac ~tpa: ip ~tha: dest_mac ~spa: ip
     )
    ) t.bound_ips
  let get_bound_ips t = t.bound_ips

  (* Set the bound IP address list, which will xmit a GARP packet also *)
  let set_bound_ips t ips =
    t.bound_ips <- ips;
    output_garp t

end
