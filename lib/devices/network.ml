open Functoria.DSL
open Functoria.Action
open Misc

type network = NETWORK

let network = typ NETWORK
let all_networks = ref []
let add_new_network name = all_networks := name :: !all_networks

let network_conf ?(intf : string runtime_arg option) name =
  let runtime_args = Option.to_list (Option.map Runtime_arg.v intf) in
  let packages_v =
    Key.match_ Key.(value target) @@ function
    | `Unix -> [ package ~sublibs:["unix"] ~min:"3.0.0" ~max:"4.0.0" "mirage-net-unix" ]
    | `MacOSX -> failwith "NYI"
    | `Xen -> failwith "NYI"
    | `Qubes -> failwith "NYI"
    | #Key.mode_solo5 -> [ package ~sublibs:["solo5"] ~min:"3.0.0" ~max:"4.0.0" "mirage-net" ]
  in
  let connect _ modname = function
    | [] -> code ~pos:__POS__ "%s.connect %S" modname name
    | [ intf ] -> code ~pos:__POS__ "%s.connect %s" modname intf
    | _ -> connect_err "network_conf" 0 ~max:1
  in
  let configure _ =
    add_new_network name;
    ok ()
  in
  impl ~runtime_args ~packages_v ~connect ~configure "Mirage_net" network

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
