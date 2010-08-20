open Printf
open Lwt
open Mpl
module MT = Mlnet_types

(* TODO: ARP timeout with an Lwt_pqueue *)
let mac_cache = Hashtbl.create 1

let dump_cache () = 
    Hashtbl.iter (fun mac ip -> 
        printf "%s -> %s\n%!" (MT.ethernet_mac_to_string mac) 
            (MT.ipv4_addr_to_string ip)) mac_cache

let recv netif (arp:Mpl_ethernet.Ethernet.ARP.o) =
    match arp#ptype with
    |`IPv4 -> begin
        match arp#operation with
        |`Request -> begin
            (* Received an ARP request; check if we can satisfy it
               from our interface *) 
             let req_ipv4 = MT.ipv4_addr_of_bytes arp#tpa in
             if req_ipv4 = netif.MT.ip then begin
                 (* someone wants us! we should reply with our MAC! *)
                 let my_mac = `Str (MT.ethernet_mac_to_bytes netif.MT.mac) in
                 let to_mac = `Str arp#src_mac in
                 let my_ipv4 = `Str (MT.ipv4_addr_to_bytes netif.MT.ip) in
                 MT.mpl_xmit_env netif (fun env ->
                   let arp_reply = Mpl_ethernet.Ethernet.ARP.t
                      ~dest_mac:to_mac
                      ~src_mac:my_mac
                      ~ptype:`IPv4
                      ~operation:`Reply
                      ~sha:my_mac
                      ~spa:my_ipv4
                      ~tha:to_mac
                      ~tpa:(`Str arp#spa) env in
                   ())
             end else
                 return () (* not a matching request *)
        end
        |`Reply ->
            let frm_mac = MT.ethernet_mac_of_bytes arp#sha in
            let frm_ip = MT.ipv4_addr_of_bytes arp#spa in
            Hashtbl.replace mac_cache frm_mac frm_ip;
            return (dump_cache())
        |`Unknown i -> 
            return ()
    end
    | _ -> return ()

(* Send gratuitous ARP, usually on interface bringup *)
let send_garp netif =
    MT.mpl_xmit_env netif (fun env ->
      ignore(Mpl_ethernet.Ethernet.ARP.t
        ~dest_mac: (`Str (MT.ethernet_mac_to_bytes MT.ethernet_mac_broadcast))
        ~src_mac: (`Str (MT.ethernet_mac_to_bytes netif.MT.mac))
        ~ptype:`IPv4
        ~operation:`Reply
        ~sha: (`Str (MT.ethernet_mac_to_bytes netif.MT.mac))
        ~tpa: (`Str (MT.ipv4_addr_to_bytes netif.MT.ip)) 
        ~tha: (`Str (MT.ethernet_mac_to_bytes MT.ethernet_mac_broadcast))
        ~spa: (`Str (MT.ipv4_addr_to_bytes netif.MT.ip)) env)
    )
