open Functoria.DSL
open Time
open Mclock
open Pclock
open Stack
open Random
open Misc
open Happy_eyeballs

type dns_client = Dns_client

let dns_client = typ Dns_client

let generic_dns_client timeout nameservers =
  let packages = [ package "dns-client-mirage" ~min:"9.0.0" ~max:"10.0.0" ] in
  let runtime_args = runtime_args_opt [ nameservers; timeout ] in
  let pp_nameservers ppf s =
    pp_label "nameservers" ppf (match s with None -> Some "[]" | _ -> s)
  in
  let err () = connect_err "generic_dns_client" 6 ~max:8 in
  let connect _info modname = function
    | _random
      :: _mclock
      :: _pclock
      :: stackv4v6
      :: happy_eyeballs
      :: _time
      :: rest ->
        let nameservers, rest = pop ~err nameservers rest in
        let timeout, rest = pop ~err timeout rest in
        let () = match rest with [] -> () | _ -> err () in
        code ~pos:__POS__ {ocaml|%s.connect @[%a%a@ (%s, %s)@]|ocaml} modname
          pp_nameservers nameservers (pp_opt "timeout") timeout stackv4v6
          happy_eyeballs
    | _ -> err ()
  in
  let extra_deps = [ dep default_time ] in
  impl ~extra_deps ~runtime_args ~packages ~connect "Dns_client_mirage.Make"
    (random
    @-> mclock
    @-> pclock
    @-> stackv4v6
    @-> happy_eyeballs
    @-> dns_client)
