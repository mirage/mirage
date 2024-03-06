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
  let runtime_args =
    match (nameservers, timeout) with
    | None, None -> []
    | None, Some timeout -> Runtime_arg.[ v timeout ]
    | Some nameservers, None -> Runtime_arg.[ v nameservers ]
    | Some nameservers, Some timeout -> Runtime_arg.[ v nameservers; v timeout ]
  in
  let connect _info modname = function
    | [ _random; _time; _mclock; _pclock; stackv4v6 ] ->
        let pp_nameservers ppf = function
          | None -> Fmt.string ppf "[]"
          | Some nameservers -> Runtime_arg.call ppf nameservers
        in
        let pp_timeout ppf = function
          | None -> ()
          | Some timeout -> Fmt.pf ppf "?timeout:%a " Runtime_arg.call timeout
        in
        Fmt.str {ocaml|%s.connect ~nameservers:%a %a%s|ocaml} modname
          pp_nameservers nameservers pp_timeout timeout stackv4v6
    | _ -> assert false
  in
  impl ~runtime_args ~packages ~connect "Dns_client_mirage.Make"
    (random @-> time @-> mclock @-> pclock @-> stackv4v6 @-> dns_client)
