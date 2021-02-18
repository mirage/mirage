open Functoria
open Mirage_impl_ip
open Mirage_impl_misc

type 'a icmp = ICMP

type icmpv4 = v4 icmp

let icmp = Type.v ICMP

let icmpv4 : icmpv4 typ = icmp

let icmpv4_direct () =
  let packages_v = right_tcpip_library ~sublibs:[ "icmpv4" ] "tcpip" in
  let connect _ modname = function
    | [ ip ] -> Fmt.strf "%s.connect %s" modname ip
    | _ -> failwith (connect_err "icmpv4" 1)
  in
  impl ~packages_v ~connect "Icmpv4.Make" (ip @-> icmp)

let direct_icmpv4 ip = icmpv4_direct () $ ip
