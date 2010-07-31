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
    let t = { Mlnet_types.nf=nf; up=up; ip=ip; netmask=netmask; gw=gw; mac=mac } in
    if default then default_netif := Some t;
    all_netif := t :: !all_netif;
    Netfront.set_recv nf (Frame.recv t);
    return t

(* Fold a function over active interfaces *)
let fold_active fn a =
    List.fold_left (fun a t ->
       if t.MT.up then fn a t else a) a !all_netif

let set_default netif = function
    | true ->
       default_netif := Some netif
    | false -> begin
        match !default_netif with
        |Some netif' when netif' = netif ->
            default_netif := None
        | _ -> ()
    end   

