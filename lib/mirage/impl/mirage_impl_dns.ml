open Functoria
open Mirage_impl_time
open Mirage_impl_mclock
open Mirage_impl_pclock
open Mirage_impl_stack
open Mirage_impl_random

type dns_client = Dns_client

let dns_client = Type.v Dns_client

let generic_dns_client timeout nameservers =
  let packages = [ package "dns-client-mirage" ~min:"7.0.0" ~max:"8.0.0" ] in
  let keys =
    match (nameservers, timeout) with
    | None, None -> []
    | None, Some timeout -> [ Key.v timeout ]
    | Some nameservers, None -> [ Key.v nameservers ]
    | Some nameservers, Some timeout -> [ Key.v nameservers; Key.v timeout ]
  in
  let connect _info modname = function
    | [ _random; _time; _mclock; _pclock; stackv4v6 ] ->
        let pp_nameservers ppf = function
          | None -> Fmt.string ppf "[]"
          | Some nameservers -> Key.serialize_call ppf (Key.v nameservers)
        in
        let pp_timeout ppf = function
          | None -> ()
          | Some timeout ->
              Fmt.pf ppf "?timeout:%a " Key.serialize_call (Key.v timeout)
        in
        Fmt.str {ocaml|%s.connect ~nameservers:%a %a%s|ocaml} modname
          pp_nameservers nameservers pp_timeout timeout stackv4v6
    | _ -> assert false
  in
  impl ~keys ~packages ~connect "Dns_client_mirage.Make"
    (random @-> time @-> mclock @-> pclock @-> stackv4v6 @-> dns_client)
