open Functoria.DSL
open Functoria.Action

type network = NETWORK

let network = typ NETWORK
let all_networks = ref []
let add_new_network name = all_networks := name :: !all_networks

let network_conf ?(intf : string runtime_arg option) name =
  let runtime_args = Option.to_list (Option.map Runtime_arg.v intf) in
  let packages_v =
    Key.match_ Key.(value target) @@ function
    | `Unix -> [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-net-unix" ]
    | `MacOSX -> [ package ~min:"1.8.0" ~max:"2.0.0" "mirage-net-macosx" ]
    | `Xen -> [ package ~min:"2.1.0" ~max:"3.0.0" "mirage-net-xen" ]
    | `Qubes ->
        [ package ~min:"2.1.0" ~max:"3.0.0" "mirage-net-xen"; Qubesdb.pkg ]
    | #Key.mode_solo5 ->
        [ package ~min:"0.8.0" ~max:"0.9.0" "mirage-net-solo5" ]
    | #Key.mode_unikraft ->
        [ package ~min:"1.0.0" ~max:"2.0.0" "mirage-net-unikraft" ]
  in
  let connect _ modname = function
    | [] -> code ~pos:__POS__ "%s.connect %S" modname name
    | [ intf ] -> code ~pos:__POS__ "%s.connect %s" modname intf
    | _ -> Misc.connect_err "network_conf (sometimes 0 arguments)" 1
  in
  let configure _ =
    add_new_network name;
    ok ()
  in
  impl ~runtime_args ~packages_v ~connect ~configure "Netif" network

let netif ?group dev =
  if_impl Key.is_solo5 (network_conf dev)
    (network_conf ~intf:(Runtime_arg.interface ?group dev) dev)

let default_network =
  match_impl
    Key.(value target)
    [
      (`Unix, netif "tap0");
      (`MacOSX, netif "tap0");
      (* On Solo5 targets, a single default network is customarily
       * named just 'service' *)
      (`Hvt, netif "service");
      (`Spt, netif "service");
      (`Virtio, netif "service");
      (`Muen, netif "service");
      (`Genode, netif "service");
    ]
    ~default:(netif "0")
