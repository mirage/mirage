open Functoria
module Key = Mirage_key

type network = NETWORK
let network = Type NETWORK

let all_networks = ref []

let network_conf (intf : string Key.key) =
  let key = Key.abstract intf in
  object
    inherit base_configurable
    method ty = network
    val name = Functoria_app.Name.create "net" ~prefix:"net"
    method name = name
    method module_name = "Netif"
    method! keys = [ key ]
    method! packages =
      Key.match_ Key.(value target) @@ function
      | `Unix -> [ package ~min:"2.6.0" ~max:"3.0.0" "mirage-net-unix" ]
      | `MacOSX -> [ package ~min:"1.6.0" ~max:"2.0.0" "mirage-net-macosx" ]
      | `Xen -> [ package ~min:"1.10.0" ~max:"2.0.0" "mirage-net-xen"]
      | `Qubes ->
        [ package ~min:"1.10.0" ~max:"2.0.0" "mirage-net-xen" ;
          Mirage_impl_qubesdb.pkg ]
      | #Mirage_key.mode_solo5 ->
        [ package ~min:"0.4.2" ~max:"0.5.0" "mirage-net-solo5" ]
    method! connect _ modname _ =
      Fmt.strf "%s.connect %a" modname Key.serialize_call key
    method! configure i =
      all_networks := Key.get (Info.context i) intf :: !all_networks;
      Rresult.R.ok ()
  end

let netif ?group dev = impl (network_conf @@ Key.interface ?group dev)
let default_network =
  match_impl Key.(value target) [
    `Unix   , netif "tap0";
    `MacOSX , netif "tap0";
    (* On Solo5 targets, a single default network is customarily
     * named just 'service' *)
    `Hvt    , netif "service";
    `Spt    , netif "service";
    `Virtio , netif "service";
    `Muen   , netif "service";
    `Genode , netif "service";
  ] ~default:(netif "0")
