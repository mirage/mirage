open Functoria
open Mirage_impl_misc
open Mirage_impl_pclock
open Mirage_impl_stack
module Key = Mirage_key
module Runtime_arg = Mirage_runtime_arg

type syslog_config = {
  hostname : string;
  server : Ipaddr.t option;
  port : int option;
  truncate : int option;
}

let syslog_config ?port ?truncate ?server hostname =
  { hostname; server; port; truncate }

let default_syslog_config =
  let hostname = "no_name"
  and server = None
  and port = None
  and truncate = None in
  { hostname; server; port; truncate }

type syslog = SYSLOG

let syslog = Type.v SYSLOG
let opt p s = Fmt.(option @@ (any ("~" ^^ s ^^ ":") ++ p))
let opt_int = opt Fmt.int
let opt_string = opt (fun pp v -> Format.fprintf pp "%S" v)
let pkg sublibs = [ package ~min:"0.4.0" ~max:"0.5.0" ~sublibs "logs-syslog" ]

let syslog_udp_conf config =
  let endpoint = Runtime_arg.syslog config.server in
  let port = Runtime_arg.syslog_port config.port in
  let hostname = Runtime_arg.syslog_hostname config.hostname in
  let packages = pkg [ "mirage" ] in
  let runtime_args = Runtime_arg.[ v endpoint; v hostname; v port ] in
  let connect _i modname = function
    | [ pclock; stack; endpoint; hostname; port ] ->
        code ~pos:__POS__
          "@[<v 2>match %s with@ | None -> Lwt.return_unit@ | Some server ->@ \
           let port = %s in@ let reporter =@ %s.create %s %s ~hostname:%s \
           ?port server %a ()@ in@ Logs.set_reporter reporter;@ \
           Lwt.return_unit@]"
          endpoint port modname pclock stack hostname (opt_int "truncate")
          config.truncate
    | _ -> connect_err "syslog_udp" 5
  in
  impl ~packages ~runtime_args ~connect "Logs_syslog_mirage.Udp"
    (pclock @-> stackv4v6 @-> syslog)

let syslog_udp ?(config = default_syslog_config) ?(clock = default_posix_clock)
    stack =
  syslog_udp_conf config $ clock $ stack

let syslog_tcp_conf config =
  let endpoint = Runtime_arg.syslog config.server in
  let port = Runtime_arg.syslog_port config.port in
  let hostname = Runtime_arg.syslog_hostname config.hostname in
  let packages = pkg [ "mirage" ] in
  let runtime_args = Runtime_arg.[ v endpoint; v hostname; v port ] in
  let connect _i modname = function
    | [ pclock; stack; endpoint; hostname; port ] ->
        code ~pos:__POS__
          "@[<v 2>match %s with@ | None -> Lwt.return_unit@ | Some server ->@ \
           let port = %s in@ %s.create %s %s ~hostname:%s ?port server %a () \
           >>= function@ | Ok reporter -> Logs.set_reporter reporter; \
           Lwt.return_unit@ | Error e -> invalid_arg e@]"
          endpoint port modname pclock stack hostname (opt_int "truncate")
          config.truncate
    | _ -> connect_err "syslog_tcp" 5
  in
  impl ~packages ~runtime_args ~connect "Logs_syslog_mirage.Tcp"
    (pclock @-> stackv4v6 @-> syslog)

let syslog_tcp ?(config = default_syslog_config) ?(clock = default_posix_clock)
    stack =
  syslog_tcp_conf config $ clock $ stack

let syslog_tls_conf ?keyname config =
  let endpoint = Runtime_arg.syslog config.server in
  let port = Runtime_arg.syslog_port config.port in
  let hostname = Runtime_arg.syslog_hostname config.hostname in
  let packages = pkg [ "mirage"; "mirage.tls" ] in
  let runtime_args = Runtime_arg.[ v endpoint; v hostname; v port ] in
  let connect _i modname = function
    | [ pclock; stack; kv; endpoint; hostname; port ] ->
        code ~pos:__POS__
          "@[<v 2>match %s with@ | None -> Lwt.return_unit@ | Some server ->@ \
           let port = %s in@ %s.create %s %s %s ~hostname:%s ?port server %a \
           %a () >>= function@ | Ok reporter -> Logs.set_reporter reporter; \
           Lwt.return_unit@ | Error e -> invalid_arg e@]"
          endpoint port modname pclock stack kv hostname (opt_int "truncate")
          config.truncate (opt_string "keyname") keyname
    | _ -> connect_err "syslog_tls" 6
  in
  impl ~packages ~runtime_args ~connect "Logs_syslog_mirage_tls.Tls"
    (pclock @-> stackv4v6 @-> Mirage_impl_kv.ro @-> syslog)

let syslog_tls ?(config = default_syslog_config) ?keyname
    ?(clock = default_posix_clock) stack kv =
  syslog_tls_conf ?keyname config $ clock $ stack $ kv
