open Lwt
open Printf
module MT = Mlnet_types

(* default interface to send traffic through *)
let default_netif = ref None

(* all registered interfaces (both active and inactive) *)
let all_netif = ref []

exception Invalid_ethernet_mac of string

let create ?(default=true) ?(up=true) ~ip ~netmask ~gw vif_id  =
    lwt nf = Netfront.create vif_id in
    lwt mac = match MT.ethernet_mac_of_string (Netfront.mac nf) with
        | Some mac -> return mac
        | None -> fail (Invalid_ethernet_mac (Netfront.mac nf)) in
    let recv = Page_stream.make () in
    let recv_cond = Lwt_condition.create () in
    let recv_pool = Lwt_pool.create 5 
       (fun () -> return (String.make 4096 '\000')) in
    let xmit = Page_stream.make () in
    let state = if true then MT.Netif_up else MT.Netif_down in
    let t = { Mlnet_types.nf=nf; ip=ip; state=state; netmask=netmask; gw=gw; 
        mac=mac; recv=recv; recv_cond=recv_cond; recv_pool=recv_pool; 
        xmit=xmit } in
    if default then default_netif := Some t;
    all_netif := t :: !all_netif;
    let recv_thread = Frame.recv_thread t in
    Netfront.set_recv nf (Frame.recv t);
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

