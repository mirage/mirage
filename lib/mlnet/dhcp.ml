(*
 * Copyright (c) 2006 Anil Madhavapeddy <anil@recoil.org>
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
open Mpl
open Mpl_dhcp
open Mpl_udp
open Mpl_ipv4
open Mpl_ethernet
module MT = Mlnet_types
module MS = Mpl_stdlib

module Options = struct

  module Marshal = struct
    let t_to_code = function
       |`Pad -> 0
       |`Subnet_mask -> 1
       |`Time_offset -> 2
       |`Router -> 3
       |`Time_server -> 4
       |`Name_server -> 5
       |`DNS_server -> 6
       |`Host_name -> 12
       |`Domain_name -> 15
       |`Requested_ip -> 50
       |`Lease_time -> 51
       |`Message_type -> 53
       |`Server_identifier -> 54
       |`Parameter_request -> 55
       |`Max_size -> 57
       |`Client_id -> 61
       |`End -> 255

    let to_byte x = String.make 1 (Char.chr (t_to_code x))

    let htonl s = 
       let x = String.create 4 in
       let (>!) x y = Int32.logand (Int32.shift_right x y) 255l in
       x.[0] <- Char.chr (Int32.to_int (s >! 24));
       x.[1] <- Char.chr (Int32.to_int (s >! 16));
       x.[2] <- Char.chr (Int32.to_int (s >! 8));
       x.[3] <- Char.chr (Int32.to_int (s >! 0));
       x

    let size x = String.make 1 (Char.chr x)
    let ip_list c x = to_byte c :: (size (List.length x * 4)) :: (List.map htonl x)
    let str c x = to_byte c :: (size (String.length x)) :: [x]
    let uint32 c x = to_byte c :: "\004" :: [htonl x]

    let to_bytes x =
       let bits = match x with
       |`Pad -> [to_byte `Pad]
       |`Subnet_mask mask -> [to_byte `Subnet_mask; htonl mask]
       |`Time_offset off -> assert false (* TODO 2s complement not uint32 *)
       |`Router ips -> ip_list `Router ips
       |`Time_server ips -> ip_list `Time_server ips
       |`Name_server ips -> ip_list `Name_server ips
       |`DNS_Server ips -> ip_list `DNS_server ips
       |`Host_name h -> str `Host_name h
       |`Domain_name n -> str `Domain_name n
       |`Requested_ip ip -> uint32 `Requested_ip ip
       |`Lease_time t -> uint32 `Lease_time t
       |`Message_type mtype ->
           let mcode = function
           |`Discover -> "\001"
           |`Offer -> "\002"
           |`Request -> "\003"
           |`Decline -> "\004"
           |`Ack -> "\005"
           |`Nak -> "\006"
           |`Release -> "\007"
           |`Inform -> "\008" in
           to_byte `Message_type :: "\001" :: [mcode mtype]
       |`Server_identifier id -> uint32 `Server_identifier id
       |`Parameter_request ps ->
           to_byte `Parameter_request :: (size (List.length ps)) :: 
               List.map to_byte ps
       |`End -> [to_byte `End]
       in String.concat "" bits

    let options mtype xs = String.concat "" (List.map to_bytes
       (`Message_type mtype :: xs @ [`End]))
  end

  module Unmarshal = struct

    exception Unknown_option of char
    let t_of_code = function
       |'\000' -> `Pad
       |'\001' -> `Subnet_mask 
       |'\002' -> `Time_offset
       |'\003' -> `Router
       |'\004' -> `Time_server
       |'\005' -> `Name_server 
       |'\006' -> `DNS_server 
       |'\012' -> `Host_name 
       |'\015' -> `Domain_name 
       |'\050' -> `Requested_ip
       |'\051' -> `Lease_time
       |'\053' -> `Message_type
       |'\054' -> `Server_identifier
       |'\055' -> `Parameter_request 
       |'\057' -> `Max_size 
       |'\061' -> `Client_id
       |'\255' -> `End
       |x -> raise (Unknown_option x)

  end
end

(* Receive a DHCP UDP packet *)
let recv netif (udp:Udp.o) =
    let dhcp = Dhcp.unmarshal udp#data_env in 
    Dhcp.prettyprint dhcp;
    return ()

(* Start a DHCP request off on an interface *)
let start_request netif =
    Lwt_pool.use netif.MT.env_pool
      (fun envbuf ->
        let env = MS.new_env envbuf in

        (* DHCP pads the MAC address to 16 bytes *)
        let chaddr = (MT.ethernet_mac_to_bytes netif.MT.mac) ^ 
          (String.make 10 '\000') in

        (* Construct DHCP request packet *)
        let dhcpfn env =
           let _ = Dhcp.t
                ~op:`BootRequest
                ~xid:0xdeadbeefl (* XXX TODO must be random *)
                ~secs:0
                ~broadcast:0
                ~ciaddr:0l ~yiaddr:0l ~siaddr:0l ~giaddr:0l
                ~chaddr:(`Str chaddr)
                ~sname:(`Str (String.make 64 '\000'))
                ~file:(`Str (String.make 128 '\000'))
                ~options:(`Str (Options.Marshal.options `Discover
                  [(`Parameter_request [`Subnet_mask; `Router])]))
             env in ()
        in

        let ip_src = MT.ipv4_addr_to_uint32 MT.ipv4_blank in
        let ip_dest = MT.ipv4_addr_to_uint32 MT.ipv4_broadcast in

        let udpfn env =
           let udpo = Udp.t
                ~source_port:68
                ~dest_port:67
                ~checksum:0
                ~data:(`Sub dhcpfn) env 
           in
           (* now apply UDP checksum *)
           let csum = Checksum.udp_checksum ip_src ip_dest udpo in
           Printf.printf "setting udp csum: %d %x\n%!" csum csum;
           (* udpo#set_checksum csum *)
        in

        let ipfn env = 
          let p =
            Ipv4.t ~id:0 ~ttl:34 ~protocol:`UDP 
              ~src:ip_src ~dest:ip_dest
              ~options:`None ~data:(`Sub udpfn) env in
          let ipcsum = Checksum.ip_checksum (p#header_end / 4) 
            (MS.env_pos env 0) in
          p#set_checksum ipcsum;
         in

        let etherfn = Ethernet.IPv4.t
            ~dest_mac:(`Str (MT.ethernet_mac_to_bytes MT.ethernet_mac_broadcast))
            ~src_mac:(`Str (MT.ethernet_mac_to_bytes netif.MT.mac))
            ~data:(`Sub ipfn)
        in
        let _ = etherfn env in
        let buf = MS.string_of_env env in (* TODO zero copy xmit *)
        Xen.Time.sleep 5. >> (* XXX debug, remove *)
        netif.MT.xmit buf
      ) >>
    return (netif.MT.dhcp <- MT.Dhcp_request_sent)


