open Lwt
open Printf
open Xen
module MT = Mlnet_types

(* default interface to send traffic through *)
let default_netif = ref None

(* all registered interfaces (both active and inactive) *)
let all_netif = ref []

exception Invalid_ethernet_mac of string
exception Invalid_mode_change

let xmit nf buf =
    Xen.Netfront.xmit nf buf 0 (String.length buf)

let create_static ?(default=true) ~ip ~netmask ~gw vif_id =
    lwt nf = Netfront.create vif_id in
    lwt mac = match MT.ethernet_mac_of_string (Netfront.mac nf) with
        | Some mac -> return mac
        | None -> fail (Invalid_ethernet_mac (Netfront.mac nf)) in
    let recv = Page_stream.make () in
    let recv_cond = Lwt_condition.create () in
    let env_pool = Lwt_pool.create 5 
       (fun () -> return (String.make 4096 '\000')) in
    let state = MT.Netif_down in
    let dhcp_cond = Lwt_condition.create () in
    let t = { MT.nf=nf; ip=ip; state=state; netmask=netmask; gw=gw; 
        mac=mac; recv=recv; recv_cond=recv_cond; env_pool=env_pool; 
        dhcp_cond=dhcp_cond; xmit=(xmit nf); dhcp=MT.DHCP.Disabled } in
    if default then default_netif := Some t;
    all_netif := t :: !all_netif;
    let recv_thread = Frame.recv_thread t in
    Netfront.set_recv nf (Frame.recv t);
    return (t, recv_thread)

let set_mode netif new_mode = 
    match new_mode, netif.MT.state with
    | MT.Netif_up, (MT.Netif_down|MT.Netif_obtaining_ip) ->
        netif.MT.state <- MT.Netif_up;
        Arp.send_garp netif
    | _, MT.Netif_shutting_down ->
        fail Invalid_mode_change
    | _ ->
        return ()

let create_dhcp ?(default=true) vif_id =
    let ip = MT.ipv4_blank in
    let netmask = MT.ipv4_blank in
    let gw = MT.ipv4_blank in
    lwt (t, recv_thread) = create_static ~default ~ip ~netmask ~gw vif_id in
    t.MT.state <- MT.Netif_obtaining_ip;
    Dhcp.Client.start_discovery t >>
    Lwt_condition.wait t.MT.dhcp_cond >>
    set_mode t MT.Netif_up >>
    return (t, recv_thread)    

(* Fold a function over active interfaces *)
let fold_active fn a =
    List.fold_left (fun a t ->
       if t.MT.state = MT.Netif_up then fn a t else a) a !all_netif

let set_default netif = function
    | true ->
       default_netif := Some netif
    | false -> begin
        match !default_netif with
        |Some netif' when netif' = netif ->
            default_netif := None
        | _ -> ()
    end   

