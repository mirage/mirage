(*
 * Copyright (c) 2006-2010 Anil Madhavapeddy <anil@recoil.org>
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
open Printf
module MT = Mlnet_types
module MS = Mpl_stdlib

module Options = struct

  (* This is a hand-crafted DHCP option parser. Did not use MPL
     here as it doesn't have enough variable length array support
     yet. At some point, this should be rewritten to use more of the
     autogen Mpl_stdlib *)

  type msg = [  (* Message types, without payloads *)
    |`Pad
    |`Subnet_mask
    |`Time_offset
    |`Router
    |`Broadcast
    |`Time_server
    |`Name_server
    |`DNS_server
    |`Netbios_name_server
    |`Host_name
    |`Domain_name
    |`Requested_ip
    |`Lease_time
    |`Message_type
    |`Server_identifier
    |`Interface_mtu
    |`Parameter_request
    |`Message
    |`Max_size
    |`Client_id
    |`Domain_search (* RFC 3397 *)
    |`End
    |`Unknown of char
  ]

  type op = [  (* DHCP operations *)
    |`Discover
    |`Offer
    |`Request
    |`Decline
    |`Ack
    |`Nak
    |`Release
    |`Inform
    |`Unknown of char
  ]

  type t = [   (* Full message payloads *)
    | `Pad
    | `Subnet_mask of MT.ipv4_addr
    | `Time_offset of string
    | `Router of MT.ipv4_addr list
    | `Broadcast of MT.ipv4_addr
    | `Time_server of MT.ipv4_addr list
    | `Name_server of MT.ipv4_addr list
    | `DNS_server of MT.ipv4_addr list
    | `Netbios_name_server of MT.ipv4_addr list
    | `Host_name of string
    | `Domain_name of string
    | `Requested_ip of MT.ipv4_addr
    | `Interface_mtu of int
    | `Lease_time of int32
    | `Message_type of op
    | `Server_identifier of MT.ipv4_addr
    | `Parameter_request of msg list
    | `Message of string
    | `Max_size of int
    | `Client_id of string
    | `Domain_search of string (* not full support yet *)
    | `Unknown of (char * string) (* code * buffer *)
    | `End 
  ]

  let msg_to_string (x:msg) =
    match x with
    |`Pad -> "Pad"
    |`Subnet_mask -> "Subnet mask"
    |`Broadcast -> "Broadcast"
    |`Time_offset -> "Time offset"
    |`Router -> "Router"
    |`Time_server -> "Time server"
    |`Name_server -> "Name server"
    |`DNS_server -> "DNS server"
    |`Host_name -> "Host name"
    |`Domain_name -> "Domain name"
    |`Requested_ip -> "Requested IP"
    |`Lease_time -> "Lease time"
    |`Message_type -> "Message type"
    |`Server_identifier -> "Server identifier"
    |`Parameter_request -> "Parameter request"
    |`Message -> "Message"
    |`Interface_mtu -> "Interface MTU"
    |`Max_size -> "Max size"
    |`Client_id -> "Client id"
    |`Domain_search -> "Domain search"
    |`Netbios_name_server -> "Netbios name server"
    |`Unknown c -> sprintf "Unknown(%d)" (Char.code c)
    |`End -> "End"

  let op_to_string (x:op) =
    match x with
    |`Discover -> "Discover"
    |`Offer -> "Offer"
    |`Request -> "Request"
    |`Decline -> "Decline"
    |`Ack -> "Ack"
    |`Nak -> "Nack"
    |`Release -> "Release"
    |`Inform -> "Inform"
    |`Unknown x -> "Unknown " ^ (string_of_int (Char.code x))
 
  let t_to_string (t:t) =
    let ip_one s ip = sprintf "%s(%s)" s (MT.ipv4_addr_to_string ip) in
    let ip_list s ips = sprintf "%s(%s)" s (String.concat "," (List.map MT.ipv4_addr_to_string ips)) in
    let str s v = sprintf "%s(%s)" s (String.escaped v) in
    let strs s v = sprintf "%s(%s)" s (String.concat "," v) in
    let i32 s v = sprintf "%s(%lu)" s v in
    match t with
    | `Pad -> "Pad"
    | `Subnet_mask ip -> ip_one "Subnet mask" ip
    | `Time_offset x -> "Time offset"
    | `Broadcast x -> ip_one "Broadcast" x
    | `Router ips  -> ip_list "Routers" ips
    | `Time_server ips -> ip_list "Time servers" ips
    | `Name_server ips -> ip_list "Name servers" ips
    | `DNS_server ips -> ip_list "DNS servers" ips
    | `Host_name s -> str "Host name" s 
    | `Domain_name s -> str "Domain name" s
    | `Requested_ip ip -> ip_one "Requested ip" ip
    | `Lease_time tm -> i32 "Lease time" tm 
    | `Message_type op -> str "Message type" (op_to_string op)
    | `Server_identifier ip -> ip_one "Server identifer" ip
    | `Parameter_request ps -> strs "Parameter request" (List.map msg_to_string ps)
    | `Message s -> str "Message" s
    | `Max_size sz -> str "Max size" (string_of_int sz)
    | `Interface_mtu sz -> str "Interface MTU" (string_of_int sz)
    | `Client_id id -> str "Client id" id
    | `Domain_search d -> str "Domain search" d
    | `Netbios_name_server d -> ip_list "NetBIOS name server" d
    | `Unknown (c,x) -> sprintf "Unknown(%d[%d])" (Char.code c) (String.length x)
    | `End -> "End"

  module Marshal = struct
    let t_to_code (x:msg) =
       match x with
       |`Pad -> 0
       |`Subnet_mask -> 1
       |`Time_offset -> 2
       |`Router -> 3
       |`Time_server -> 4
       |`Name_server -> 5
       |`DNS_server -> 6
       |`Host_name -> 12
       |`Domain_name -> 15
       |`Interface_mtu -> 26
       |`Broadcast -> 28
       |`Netbios_name_server -> 44
       |`Requested_ip -> 50
       |`Lease_time -> 51
       |`Message_type -> 53
       |`Server_identifier -> 54
       |`Parameter_request -> 55
       |`Message -> 56
       |`Max_size -> 57
       |`Client_id -> 61
       |`Domain_search -> 119
       |`End -> 255
       |`Unknown c -> Char.code c

    let to_byte x = String.make 1 (Char.chr (t_to_code x))

    let uint32_to_bytes s = 
       let x = String.create 4 in
       let (>!) x y = Int32.logand (Int32.shift_right x y) 255l in
       x.[0] <- Char.chr (Int32.to_int (s >! 24));
       x.[1] <- Char.chr (Int32.to_int (s >! 16));
       x.[2] <- Char.chr (Int32.to_int (s >! 8));
       x.[3] <- Char.chr (Int32.to_int (s >! 0));
       x

    let uint16_to_bytes s =
       let x = String.create 2 in
       x.[0] <- Char.chr (s land 255);
       x.[1] <- Char.chr ((s lsl 8) land 255);
       x

    let size x = String.make 1 (Char.chr x)
    let ip_list c ips = 
       let x = List.map MT.ipv4_addr_to_bytes ips in
       to_byte c :: (size (List.length x * 4)) :: x
    let ip_one c x = to_byte c :: ["\004"; MT.ipv4_addr_to_bytes x]
    let str c x = to_byte c :: (size (String.length x)) :: [x]
    let uint32 c x = to_byte c :: [ "\004"; uint32_to_bytes x]
    let uint16 c x = to_byte c :: [ "\002"; uint16_to_bytes x]
    let to_bytes (x:t) =
       let bits = match x with
       |`Pad -> [to_byte `Pad]
       |`Subnet_mask mask -> ip_one `Subnet_mask mask
       |`Time_offset off -> assert false (* TODO 2s complement not uint32 *)
       |`Router ips -> ip_list `Router ips
       |`Broadcast ip -> ip_one `Broadcast ip
       |`Time_server ips -> ip_list `Time_server ips
       |`Name_server ips -> ip_list `Name_server ips
       |`DNS_server ips -> ip_list `DNS_server ips
       |`Netbios_name_server ips -> ip_list `Netbios_name_server ips
       |`Host_name h -> str `Host_name h
       |`Domain_name n -> str `Domain_name n
       |`Requested_ip ip -> ip_one `Requested_ip ip
       |`Lease_time t -> uint32 `Lease_time t
       |`Message x -> str `Message x
       |`Max_size s -> uint16 `Max_size s
       |`Interface_mtu s -> uint16 `Interface_mtu s
       |`Message_type mtype ->
           let mcode = function
           |`Discover -> "\001"
           |`Offer -> "\002"
           |`Request -> "\003"
           |`Decline -> "\004"
           |`Ack -> "\005"
           |`Nak -> "\006"
           |`Release -> "\007"
           |`Inform -> "\008"
           |`Unknown x -> String.make 1 x in
           to_byte `Message_type :: "\001" :: [mcode mtype]
       |`Server_identifier id -> ip_one `Server_identifier id
       |`Parameter_request ps ->
           to_byte `Parameter_request :: (size (List.length ps)) :: 
               List.map to_byte ps
       |`Client_id s ->
           let s' = "\000" ^ s in (* only support domain name ids *)
           str `Client_id s'
       |`Domain_search s ->
           assert false (* not supported yet, requires annoying DNS compression *)
       |`End -> [to_byte `End]
       |`Unknown (c,x) -> [ (String.make 1 c); x ]
       in String.concat "" bits

    let options mtype xs = 
       let buf = String.make 312 '\000' in
       let p = String.concat "" (List.map to_bytes (`Message_type mtype :: xs @ [`End])) in
       (* DHCP packets have minimum length, hence the blit into buf *)
       String.blit p 0 buf 0 (String.length p);
       buf
  end

  module Unmarshal = struct

    exception Error of string

    let msg_of_code x : msg =
       match x with
       |'\000' -> `Pad
       |'\001' -> `Subnet_mask 
       |'\002' -> `Time_offset
       |'\003' -> `Router
       |'\004' -> `Time_server
       |'\005' -> `Name_server 
       |'\006' -> `DNS_server 
       |'\012' -> `Host_name 
       |'\015' -> `Domain_name 
       |'\026' -> `Interface_mtu
       |'\028' -> `Broadcast
       |'\044' -> `Netbios_name_server
       |'\050' -> `Requested_ip
       |'\051' -> `Lease_time
       |'\053' -> `Message_type
       |'\054' -> `Server_identifier
       |'\055' -> `Parameter_request 
       |'\056' -> `Message
       |'\057' -> `Max_size 
       |'\061' -> `Client_id
       |'\119' -> `Domain_search
       |'\255' -> `End
       |x -> `Unknown x

    let of_bytes buf : t list =
       let pos = ref 0 in
       let getc () =  (* Get one character *)
         let r = String.get buf !pos in
         pos := !pos + 1;
         r in
       let getint () = (* Get one integer *)
         Char.code (getc ()) in
       let slice len = (* Get a substring *)
         let r = String.sub buf !pos len in
         pos := !pos + len;
         r in
       let check c = (* Check that a char is the provided value *)
         let r = getc () in 
         if r != c then raise (Error (sprintf "check failed at %d != %d" !pos (Char.code c))) in
       let get_addr fn = (* Get one address *)
         check '\004';
         fn (slice 4) in
       let get_addrs fn = (* Repeat fn n times and return the list *)
         let len = getint () / 4 in
         let res = ref [] in 
         for i = 1 to len do
           res := (fn (slice 4)) :: !res
         done;
         List.rev !res in 
       let uint32_of_bytes x =
         let fn p = Int32.shift_left (Int32.of_int (Char.code x.[p])) ((3-p)*8) in
         let (++) = Int32.add in
         (fn 0) ++ (fn 1) ++ (fn 2) ++ (fn 3) in
       let rec fn acc =
          let cont (r:t) = fn (r :: acc) in
          let code = msg_of_code (getc ()) in
          match code with
          |`Pad -> fn acc
          |`Subnet_mask -> cont (`Subnet_mask (get_addr MT.ipv4_addr_of_bytes))
          |`Time_offset -> cont (`Time_offset (get_addr (fun x -> x)))
          |`Router -> cont (`Router (get_addrs MT.ipv4_addr_of_bytes))
          |`Broadcast -> cont (`Broadcast (get_addr MT.ipv4_addr_of_bytes))
          |`Time_server -> cont (`Time_server (get_addrs MT.ipv4_addr_of_bytes))
          |`Name_server -> cont (`Name_server (get_addrs MT.ipv4_addr_of_bytes))
          |`DNS_server -> cont (`DNS_server (get_addrs MT.ipv4_addr_of_bytes))
          |`Host_name -> cont (`Host_name (slice (getint ())))
          |`Domain_name -> cont (`Domain_name (slice (getint ())))
          |`Requested_ip -> cont (`Requested_ip (get_addr MT.ipv4_addr_of_bytes))
          |`Server_identifier -> cont (`Server_identifier (get_addr MT.ipv4_addr_of_bytes)) 
          |`Lease_time -> cont (`Lease_time (get_addr uint32_of_bytes))
          |`Domain_search -> cont (`Domain_search (slice (getint())))
          |`Netbios_name_server -> cont (`Netbios_name_server (get_addrs MT.ipv4_addr_of_bytes))
          |`Message -> cont (`Message (slice (getint ())))
          |`Message_type ->
              check '\001';
              let mcode = match (getc ()) with
              |'\001' -> `Discover
              |'\002' -> `Offer 
              |'\003' -> `Request 
              |'\004' -> `Decline
              |'\005' -> `Ack
              |'\006' -> `Nak
              |'\007' -> `Release
              |'\008'  -> `Inform
              |x -> `Unknown x in
              cont (`Message_type mcode)
          |`Parameter_request ->
              let len = getint () in
              let params = ref [] in
              for i = 1 to len do
                 params := (msg_of_code (getc ())) :: !params
              done;
              cont (`Parameter_request (List.rev !params))
          |`Max_size ->
              let l1 = getint () lsl 8 in
              cont (`Max_size (getint () + l1))
          |`Interface_mtu ->
              let l1 = getint () lsl 8 in
              cont (`Interface_mtu (getint () + l1))
          |`Client_id ->
              let len = getint () in 
              let _ = getint () in 
              cont (`Client_id (slice len))
          |`End -> acc
          |`Unknown c -> cont (`Unknown (c, (slice (getint ()))))
       in
       fn []       
  end 

  module Packet = struct
    type p  = {
      op: op;
      opts: t list;
    }

    let of_bytes buf =
       let opts = Unmarshal.of_bytes buf in
       let mtype, rest = List.partition (function `Message_type _ -> true |_ -> false) opts in
       let op = match mtype with [ `Message_type m ] -> m |_ -> raise (Unmarshal.Error "no mtype") in
       { op=op; opts=rest }

    let to_bytes p =
       Marshal.options p.op p.opts

    let prettyprint t =
       sprintf "%s : %s" (op_to_string t.op) (String.concat ", " (List.map t_to_string t.opts))

    (* Find an option in a packet *)
    let find p fn = 
       List.fold_left (fun a b ->
           match fn b with 
           |Some x -> Some x
           |None -> a) None p.opts

    (* Find an option list, and return empty list if opt doesnt exist *)
    let findl p fn =
       match find p fn with
       |Some l -> l
       |None -> []
  end
end

module Client = struct

  (* Send a client broadcast packet *)
   let send_broadcast netif ~xid ~yiaddr ~siaddr ~options =
     MT.mpl_xmit_env netif (fun env ->
       (* DHCP pads the MAC address to 16 bytes *)
       let chaddr = `Str ((MT.ethernet_mac_to_bytes netif.MT.mac) ^ 
         (String.make 10 '\000')) in

       let options = `Str (Options.Packet.to_bytes options) in

       let dhcpfn env =
          let _ = Dhcp.t
             ~op:`BootRequest
             ~xid ~secs:10
             ~broadcast:0
             ~ciaddr:0l 
             ~yiaddr:(MT.ipv4_addr_to_uint32 yiaddr) 
             ~siaddr:(MT.ipv4_addr_to_uint32 siaddr)
             ~giaddr:0l
             ~chaddr 
             ~sname:(`Str (String.make 64 '\000'))
             ~file:(`Str (String.make 128 '\000'))
             ~options env in ()
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
           let _ = Checksum.udp_checksum ip_src ip_dest udpo in
           (* udpo#set_checksum csum *)
           ()
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
        ignore(etherfn env)
   )         

   (* Receive a DHCP UDP packet *)
   let recv netif (udp:Udp.o) =
       let dhcp = Dhcp.unmarshal udp#data_env in 
       let packet = Options.Packet.of_bytes dhcp#options in
       (* See what state our Netif is in and if this packet is useful *)
       match netif.MT.dhcp with
       |MT.DHCP.Request_sent xid -> begin
           (* we are expecting an offer *)
           match packet.Options.Packet.op, dhcp#xid with 
           |`Offer, offer_xid when offer_xid=xid ->  begin
              let ip = MT.ipv4_addr_of_uint32 dhcp#yiaddr in
              printf "Offer received: %s\n%!" (MT.ipv4_addr_to_string ip);
              let netmask = Options.Packet.find packet (function `Subnet_mask addr -> Some addr |_ -> None) in
              let gw = Options.Packet.findl packet (function `Router addrs -> Some addrs |_ -> None) in
              let dns = Options.Packet.findl packet (function `DNS_server addrs -> Some addrs |_ -> None) in
              let offer = { MT.DHCP.ip=ip; netmask=netmask; gw=gw; dns=dns; lease_until=0.; xid=xid } in
              let yiaddr = MT.ipv4_addr_of_uint32 dhcp#yiaddr in
              let siaddr = MT.ipv4_addr_of_uint32 dhcp#siaddr in
              let options = { Options.Packet.op=`Request; opts= [
                  `Requested_ip ip;
                  `Server_identifier siaddr;
                ] } in
              send_broadcast netif ~xid ~yiaddr ~siaddr ~options >>
              return (netif.MT.dhcp <- MT.DHCP.Offer_accepted offer)
            end
            |_ -> print_endline "not an offer for us, ignoring"; return ()
       end
       |MT.DHCP.Offer_accepted info -> begin
           (* we are expecting an ACK *)
           match packet.Options.Packet.op, dhcp#xid with 
           |`Ack, ack_xid when ack_xid = info.MT.DHCP.xid -> begin
              let lease_time =
                match Options.Packet.find packet (function `Lease_time lt -> Some lt |_ -> None) with
                |None -> 300l (* Just leg it and assume a lease time of 5 minutes *)
                |Some x -> x in
              let lease_until = Xen.Clock.time () +. (Int32.to_float lease_time) in
              let info = { info with MT.DHCP.lease_until=lease_until } in
              (* TODO also merge in additional requested options here *)
              netif.MT.dhcp <- MT.DHCP.Lease_held info;
              (* notify the waiting Netif that DHCP is up *)
              Lwt_condition.signal netif.MT.dhcp_cond ();
              return ()
           end
           |_ -> print_endline "not an ack for us, ignoring"; return ()
       end
       |_ -> return (print_endline "other dhcp state")

 
    (* Start a DHCP discovery off on an interface *)
    let start_discovery netif =
       let xid = Random.int32 Int32.max_int in
       let yiaddr = MT.ipv4_blank in
       let siaddr = MT.ipv4_blank in
       let options = { Options.Packet.op=`Discover; opts= [
           (`Parameter_request [`Subnet_mask; `Router; `DNS_server; `Broadcast]);
           (`Host_name "miragevm")
          ] } in
       send_broadcast netif ~xid ~yiaddr ~siaddr ~options >>
       return (netif.MT.dhcp <- MT.DHCP.Request_sent xid)

end
