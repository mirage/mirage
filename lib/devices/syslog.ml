open Functoria.DSL
open Misc
open Stack

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

let syslog = typ SYSLOG
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
    | [ stack; endpoint; hostname; port ] ->
        code ~pos:__POS__
          "@[<v 2>match %s with@ | None -> Lwt.return_unit@ | Some server ->@ \
           let port = %s in@ let reporter =@ %s.create %s ~hostname:%s ?port \
           server %a ()@ in@ Logs.set_reporter reporter;@ Lwt.return_unit@]"
          endpoint port modname stack hostname (opt_int "truncate")
          config.truncate
    | _ -> connect_err "syslog_udp" 4
  in
  impl ~packages ~runtime_args ~connect "Logs_syslog_mirage.Udp"
    (stackv4v6 @-> syslog)

let syslog_udp ?(config = default_syslog_config) stack =
  syslog_udp_conf config $ stack

let syslog_tcp_conf config =
  let endpoint = Runtime_arg.syslog config.server in
  let port = Runtime_arg.syslog_port config.port in
  let hostname = Runtime_arg.syslog_hostname config.hostname in
  let packages = pkg [ "mirage" ] in
  let runtime_args = Runtime_arg.[ v endpoint; v hostname; v port ] in
  let connect _i modname = function
    | [ stack; endpoint; hostname; port ] ->
        code ~pos:__POS__
          "@[<v 2>match %s with@ | None -> Lwt.return_unit@ | Some server ->@ \
           let port = %s in@ %s.create %s ~hostname:%s ?port server %a () >>= \
           function@ | Ok reporter -> Logs.set_reporter reporter; \
           Lwt.return_unit@ | Error e -> invalid_arg e@]"
          endpoint port modname stack hostname (opt_int "truncate")
          config.truncate
    | _ -> connect_err "syslog_tcp" 4
  in
  impl ~packages ~runtime_args ~connect "Logs_syslog_mirage.Tcp"
    (stackv4v6 @-> syslog)

let syslog_tcp ?(config = default_syslog_config) stack =
  syslog_tcp_conf config $ stack

let syslog_tls_conf ?keyname config =
  let endpoint = Runtime_arg.syslog config.server in
  let port = Runtime_arg.syslog_port config.port in
  let hostname = Runtime_arg.syslog_hostname config.hostname in
  let packages = pkg [ "mirage"; "mirage.tls" ] in
  let runtime_args = Runtime_arg.[ v endpoint; v hostname; v port ] in
  let connect _i modname = function
    | [ stack; kv; endpoint; hostname; port ] ->
        code ~pos:__POS__
          "@[<v 2>match %s with@ | None -> Lwt.return_unit@ | Some server ->@ \
           let port = %s in@ %s.create %s %s ~hostname:%s ?port server %a %a \
           () >>= function@ | Ok reporter -> Logs.set_reporter reporter; \
           Lwt.return_unit@ | Error e -> invalid_arg e@]"
          endpoint port modname stack kv hostname (opt_int "truncate")
          config.truncate (opt_string "keyname") keyname
    | _ -> connect_err "syslog_tls" 5
  in
  impl ~packages ~runtime_args ~connect "Logs_syslog_mirage_tls.Tls"
    (stackv4v6 @-> Kv.ro @-> syslog)

let syslog_tls ?(config = default_syslog_config) ?keyname stack kv =
  syslog_tls_conf ?keyname config $ stack $ kv
