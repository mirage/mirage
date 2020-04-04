open Functoria
module Key = Mirage_key

type network = NETWORK

let network = Type.v NETWORK

let all_networks = ref []

let network_conf (intf : string Key.key) =
  let key = Key.v intf in
  let keys = [ key ] in
  let packages_v =
    Key.match_ Key.(value target) @@ function
    | `Unix -> [ package ~min:"2.7.0" ~max:"3.0.0" "mirage-net-unix" ]
    | `MacOSX -> [ package ~min:"1.8.0" ~max:"2.0.0" "mirage-net-macosx" ]
    | `Xen -> [ package ~min:"1.13.0" ~max:"2.0.0" "mirage-net-xen" ]
    | `Qubes ->
        [
          package ~min:"1.13.0" ~max:"2.0.0" "mirage-net-xen";
          Mirage_impl_qubesdb.pkg;
        ]
    | #Mirage_key.mode_solo5 ->
        [ package ~min:"0.6.1" ~max:"0.7.0" "mirage-net-solo5" ]
  in
  let connect _ modname _ =
    (* @samoht: why not just use the args paramater? *)
    Fmt.strf "%s.connect %a" modname Key.serialize_call key
  in
  let build i =
    all_networks := Key.get (Info.context i) intf :: !all_networks;
    Action.ok ()
  in
  impl ~keys ~packages_v ~connect ~build "Netif" network

let netif ?group dev = network_conf @@ Key.interface ?group dev

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
