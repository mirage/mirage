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

let generic_dns_client ?group ?timeout ?nameservers ?cache_size () =
  let packages = [ package "dns-client-mirage" ~min:"9.0.0" ~max:"10.0.0" ] in
  let nameservers = Runtime_arg.dns_servers ?group nameservers
  and timeout = Runtime_arg.dns_timeout ?group timeout
  and cache_size = Runtime_arg.dns_cache_size ?group cache_size in
  let runtime_args = Runtime_arg.[ v nameservers; v timeout; v cache_size ] in
  let connect _info modname = function
    | [
        _random;
        _time;
        _mclock;
        _pclock;
        stackv4v6;
        happy_eyeballs;
        nameservers;
        timeout;
        cache_size;
      ] ->
        code ~pos:__POS__
          {ocaml|%s.connect @[?nameservers:%s ?timeout:%s ?cache_size:%s@ (%s, %s)@]|ocaml}
          modname nameservers timeout cache_size stackv4v6 happy_eyeballs
    | _ -> connect_err "generic_dns_client" 8
  in
  impl ~runtime_args ~packages ~connect "Dns_client_mirage.Make"
    (random
    @-> time
    @-> mclock
    @-> pclock
    @-> stackv4v6
    @-> happy_eyeballs
    @-> dns_client)
