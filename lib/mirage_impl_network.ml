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
      | `Unix -> [ package ~min:"2.3.0" "mirage-net-unix" ]
      | `MacOSX -> [ package ~min:"1.3.0" "mirage-net-macosx" ]
      | `Xen -> [ package ~min:"1.7.0" "mirage-net-xen"]
      | `Qubes -> [ package ~min:"1.7.0" "mirage-net-xen" ; package ~min:"0.4" "mirage-qubes" ]
      | `Virtio | `Hvt | `Muen | `Genode -> [ package ~min:"0.3.0" "mirage-net-solo5" ]
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
  ] ~default:(netif "0")
