open Functoria
open Mirage_impl_time
open Mirage_impl_mclock
open Mirage_impl_pclock
open Mirage_impl_stack
open Mirage_impl_random
open Mirage_impl_misc

type dns_client = Dns_client

let dns_client = Type.v Dns_client

let generic_dns_client timeout nameservers =
  let packages = [ package "dns-client-mirage" ~min:"7.0.0" ~max:"8.0.0" ] in
  let runtime_args = runtime_args_opt [ nameservers; timeout ] in
  let pp_nameservers ppf = function
    | None -> Fmt.pf ppf "@ ~nameservers:[]"
    | key -> pp_label "nameservers" ppf key
  in
  let connect _info modname = function
    | [ _random; _time; _mclock; _pclock; stackv4v6 ] ->
        Fmt.str {ocaml|%s.connect%a%a %s|ocaml} modname pp_nameservers
          nameservers (pp_opt "timeout") timeout stackv4v6
    | _ -> assert false
  in
  impl ~runtime_args ~packages ~connect "Dns_client_mirage.Make"
    (random @-> time @-> mclock @-> pclock @-> stackv4v6 @-> dns_client)
