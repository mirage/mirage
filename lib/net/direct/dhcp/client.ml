(*
 * Copyright (c) 2006-2011 Anil Madhavapeddy <anil@recoil.org>
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
open Printf
open Nettypes

type offer = {
  ip_addr: ipv4_addr;
  netmask: ipv4_addr option;
  gateways: ipv4_addr list;
  dns: ipv4_addr list;
  lease: int32;
  xid: int32;
}

type state = 
  | Disabled
  | Request_sent of int32
  | Offer_accepted of offer
  | Lease_held of offer
  | Shutting_down

type t = {
  udp: Udp.t;
  ip: Ipv4.t;
  mutable state: state;
  new_offer: offer -> unit Lwt.t;
}

cstruct dhcp {
  uint8_t op;
  uint8_t htype;
  uint8_t hlen;
  uint8_t hops;
  uint32_t xid;
  uint16_t secs;
  uint16_t flags;
  uint32_t ciaddr;
  uint32_t yiaddr;
  uint32_t siaddr;
  uint32_t giaddr;
  uint8_t chaddr[16];
  uint8_t sname[64];
  uint8_t file[128];
  uint32_t cookie
} as big_endian

cenum mode {
  BootRequest = 1;
  BootReply
} as uint8_t

(* Send a client broadcast packet *)
let output_broadcast t ~xid ~yiaddr ~siaddr ~options =
  lwt buf = Udp.get_writebuf ~dest_ip:ipv4_broadcast ~source_port:68 ~dest_port:67 t.udp in
  set_dhcp_op buf (mode_to_int BootRequest);
  set_dhcp_htype buf 1;
  set_dhcp_hlen buf 6;
  set_dhcp_hops buf 0;
  set_dhcp_xid buf xid;
  set_dhcp_secs buf 10; (* TODO dynamic timer *)
  set_dhcp_flags buf 0;
  set_dhcp_ciaddr buf 0l;
  set_dhcp_yiaddr buf (ipv4_addr_to_uint32 yiaddr); 
  set_dhcp_siaddr buf (ipv4_addr_to_uint32 siaddr);
  set_dhcp_giaddr buf 0l;
  (* TODO add a pad/fill function in cstruct *)
  set_dhcp_chaddr (ethernet_mac_to_bytes (Ipv4.mac t.ip) ^ (String.make 10 '\000')) 0 buf;
  set_dhcp_sname (String.make 64 '\000') 0 buf;
  set_dhcp_file (String.make 128 '\000') 0 buf;
  set_dhcp_cookie buf 0x63825363l;
  let options = Option.Packet.to_bytes options in
  let options_len = String.length options in
  Cstruct.set_buffer options 0 buf sizeof_dhcp options_len;
  let buf = Cstruct.sub buf 0 (sizeof_dhcp+options_len) in
  Printf.printf "Sending DHCP broadcast\n%!";
  Udp.output t.udp buf

(* Receive a DHCP UDP packet *)
let input t ~src ~dst ~source_port buf =
  let ciaddr = ipv4_addr_of_uint32 (get_dhcp_ciaddr buf) in
  let yiaddr = ipv4_addr_of_uint32 (get_dhcp_yiaddr buf) in
  let siaddr = ipv4_addr_of_uint32 (get_dhcp_siaddr buf) in
  let giaddr = ipv4_addr_of_uint32 (get_dhcp_giaddr buf) in
  let xid = get_dhcp_xid buf in
  let options = Cstruct.(copy_buffer buf sizeof_dhcp (len buf - sizeof_dhcp)) in
  let packet = Option.Packet.of_bytes options in
  (* For debugging, print out the DHCP response *)
  Printf.printf "DHCP: input ciaddr %s yiaddr %s siaddr %s giaddr %s chaddr %s sname %s file %s\n"
    (ipv4_addr_to_string ciaddr) (ipv4_addr_to_string yiaddr)
    (ipv4_addr_to_string siaddr) (ipv4_addr_to_string giaddr)
    (copy_dhcp_chaddr buf) (copy_dhcp_sname buf) (copy_dhcp_file buf);
  (* See what state our Netif is in and if this packet is useful *)
  Option.Packet.(match t.state with
    | Request_sent xid -> begin
      (* we are expecting an offer *)
      match packet.op, xid with 
      |`Offer, offer_xid when offer_xid=xid ->  begin
            printf "DHCP: offer received: %s\n%!" (ipv4_addr_to_string yiaddr);
            let netmask = find packet
              (function `Subnet_mask addr -> Some addr |_ -> None) in
            let gateways = findl packet 
              (function `Router addrs -> Some addrs |_ -> None) in
            let dns = findl packet 
              (function `DNS_server addrs -> Some addrs |_ -> None) in
            let lease = 0l in
            let offer = { ip_addr=yiaddr; netmask; gateways; dns; lease; xid } in
            (* RFC2131 defines the 'siaddr' as the address of the server which
               will take part in the next stage of the bootstrap process (eg
               'delivery of an operating system executable image'). This
               may or may not be the address of the DHCP server. However
               'a DHCP server always returns its own address in the server
               identifier option' *)
            let server_identifier = find packet
              (function `Server_identifier addr -> Some addr | _ -> None) in
            let options = { op=`Request; opts=
                `Requested_ip yiaddr :: (
                  match server_identifier with
                  | Some x -> [ `Server_identifier x ]
                  | None -> []
                )
            } in
            t.state <- Offer_accepted offer;
            output_broadcast t ~xid ~yiaddr ~siaddr ~options
        end
        |_ -> printf "DHCP: offer not for us"; return ()
    end
    | Offer_accepted info -> begin
        (* we are expecting an ACK *)
        match packet.op, xid with
        |`Ack, ack_xid when ack_xid = info.xid -> begin
            let lease =
              match find packet (function `Lease_time lt -> Some lt |_ -> None) with
              | None -> 300l (* Just leg it and assume a lease time of 5 minutes *)
              | Some x -> x in
            let info = { info with lease=lease } in
            (* TODO also merge in additional requested options here *)
            t.state <- Lease_held info;
            t.new_offer info
       end
       |_ -> printf "DHCP: ack not for us\n%!"; return ()
    end
    |Shutting_down -> return ()
    |Lease_held info -> printf "DHCP input: lease already held\n%!"; return ()
    |Disabled -> printf "DHCP input: disabled\n%!"; return ()
  )
 
(* Start a DHCP discovery off on an interface *)
let start_discovery t =
  OS.Time.sleep 0.2 >>
  let xid = Random.int32 Int32.max_int in
  let yiaddr = ipv4_blank in
  let siaddr = ipv4_blank in
  let options = { Option.Packet.op=`Discover; opts= [
    (`Parameter_request [`Subnet_mask; `Router; `DNS_server; `Broadcast]);
    (`Host_name "miragevm")
  ] } in
  Printf.printf "DHCP: start discovery\n%!";
  t.state <- Request_sent xid;
  output_broadcast t ~xid ~yiaddr ~siaddr ~options >>
  return ()

(* DHCP state thred *)
let rec dhcp_thread t =
  (* For now, just send out regular discoveries until we have a lease *)
  match t.state with
  |Disabled |Request_sent _ ->
    start_discovery t >>
    OS.Time.sleep 10. >>
    dhcp_thread t
  |Shutting_down ->
    printf "DHCP thread: done\n%!";
    return ()
  |_ -> 
    (* TODO: This should be looking at the lease time *)
    OS.Time.sleep 3600. >>
    dhcp_thread t

(* Create a DHCP thread *)
let create ip udp =
  let thread,_ = Lwt.task () in
  let state = Disabled in
  (* For now, just block on the first offer
     and shut down DHCP after. TODO: full protocol *)
  let first_t, first_u = Lwt.task () in
  let new_offer info =
    Printf.printf "DHCP: offer %s %s [%s]\n%!"
      (ipv4_addr_to_string info.ip_addr)
      (match info.netmask with |Some ip -> ipv4_addr_to_string ip |None -> "None")
      (String.concat ", " (List.map ipv4_addr_to_string info.gateways));
    Ipv4.set_ip ip info.ip_addr >>
    (match info.netmask with 
     |Some nm -> Ipv4.set_netmask ip nm
     |None -> return ()) >>
    Ipv4.set_gateways ip info.gateways >>
    return (Lwt.wakeup first_u ())
  in
  let t = { ip; udp; state; new_offer } in
  let listen_t = Udp.listen t.udp 68 (input t) in
  Lwt.on_cancel thread (fun () ->
    printf "DHCP: shutting down\n%!";
    t.state <- Shutting_down;
    Lwt.cancel listen_t
  );
  let th = dhcp_thread t <&> listen_t <&> thread in
  Printf.printf "DHCP: waiting for first offer\n%!";
  first_t >>
  return (t, th)
