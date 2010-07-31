open Printf
module MT = Mlnet_types

(* TODO: ARP timeout with an Lwt_pqueue *)
let mac_cache = Hashtbl.create 1

let dump_cache () = 
    Hashtbl.iter (fun mac ip -> 
        printf "%s -> %s\n%!" (MT.ethernet_mac_to_string mac) 
            (MT.ipv4_addr_to_string ip)) mac_cache

let recv nf (arp:Mpl_ethernet.Ethernet.ARP.o) =
    match arp#ptype with
    |`IPv4 -> begin
        match arp#operation with
        |`Request ->
            (* Received an ARP request; check if we can satisfy it
               from our interface set *) 
             ()
        |`Reply ->
            let frm_mac = MT.ethernet_mac_of_bytes arp#sha in
            let frm_ip = MT.ipv4_addr_of_bytes arp#spa in
            Hashtbl.replace mac_cache frm_mac frm_ip;
            dump_cache()
        |`Unknown i -> ()
    end
    | _ -> ()
