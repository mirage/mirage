open Functoria
open Mirage_impl_console
open Mirage_impl_misc
open Mirage_impl_pclock
open Mirage_impl_stackv4

module Key = Mirage_key

type syslog_config = {
  hostname : string;
  server   : Ipaddr.V4.t option;
  port     : int option;
  truncate : int option;
}

let syslog_config ?port ?truncate ?server hostname = {
  hostname ; server ; port ; truncate
}

let default_syslog_config =
  let hostname = "no_name"
  and server = None
  and port = None
  and truncate = None
  in
  { hostname ; server ; port ; truncate }

type syslog = SYSLOG
let syslog = Type SYSLOG

let opt p s = Fmt.(option @@ prefix (unit ("~"^^s^^":")) p)
let opt_int = opt Fmt.int
let opt_string = opt (fun pp v -> Format.fprintf pp "%S" v)

let pkg sublibs =
  Key.pure [ package ~min:"0.2.2" ~max:"0.3.0" ~sublibs "logs-syslog" ]

let syslog_udp_conf config =
  let endpoint = Key.syslog config.server
  and port = Key.syslog_port config.port
  and hostname = Key.syslog_hostname config.hostname
  in
  impl @@ object
    inherit base_configurable
    method ty = console @-> pclock @-> stackv4 @-> syslog
    method name = "udp_syslog"
    method module_name = "Logs_syslog_mirage.Udp"
    method! packages = pkg ["mirage"]
    method! keys =
      [ Key.abstract endpoint ; Key.abstract hostname ; Key.abstract port ]
    method! connect _i modname = function
      | [ console ; pclock ; stack ] ->
        Fmt.strf
          "@[<v 2>\
           match %a with@ \
           | None -> Lwt.return_unit@ \
           | Some server ->@ \
             let port = %a in@ \
             let reporter =@ \
               %s.create %s %s %s ~hostname:%a ?port server %a ()@ \
             in@ \
             Logs.set_reporter reporter;@ \
             Lwt.return_unit@]"
          pp_key endpoint
          pp_key port
          modname console pclock stack
          pp_key hostname
          (opt_int "truncate") config.truncate
      | _ -> failwith (connect_err "syslog udp" 3)
  end

let syslog_udp ?(config = default_syslog_config) ?(console = default_console) ?(clock = default_posix_clock) stack =
  syslog_udp_conf config $ console $ clock $ stack

let syslog_tcp_conf config =
  let endpoint = Key.syslog config.server
  and port = Key.syslog_port config.port
  and hostname = Key.syslog_hostname config.hostname
  in
  impl @@ object
    inherit base_configurable
    method ty = console @-> pclock @-> stackv4 @-> syslog
    method name = "tcp_syslog"
    method module_name = "Logs_syslog_mirage.Tcp"
    method! packages = pkg ["mirage"]
    method! keys =
      [ Key.abstract endpoint ; Key.abstract hostname ; Key.abstract port ]
    method! connect _i modname = function
      | [ console ; pclock ; stack ] ->
        Fmt.strf
          "@[<v 2>\
           match %a with@ \
           | None -> Lwt.return_unit@ \
           | Some server ->@ \
             let port = %a in@ \
             %s.create %s %s %s ~hostname:%a ?port server %a () >>= function@ \
             | Ok reporter -> Logs.set_reporter reporter; Lwt.return_unit@ \
             | Error e -> invalid_arg e@]"
          pp_key endpoint
          pp_key port
          modname console pclock stack
          pp_key hostname
          (opt_int "truncate") config.truncate
      | _ -> failwith (connect_err "syslog tcp" 3)
  end

let syslog_tcp ?(config = default_syslog_config) ?(console = default_console) ?(clock = default_posix_clock) stack =
  syslog_tcp_conf config $ console $ clock $ stack

let syslog_tls_conf ?keyname config =
  let endpoint = Key.syslog config.server
  and port = Key.syslog_port config.port
  and hostname = Key.syslog_hostname config.hostname
  in
  impl @@ object
    inherit base_configurable
    method ty = console @-> pclock @-> stackv4 @-> Mirage_impl_kv.ro @-> syslog
    method name = "tls_syslog"
    method module_name = "Logs_syslog_mirage_tls.Tls"
    method! packages = pkg ["mirage" ; "mirage.tls"]
    method! keys = [ Key.abstract endpoint ; Key.abstract hostname ; Key.abstract port ]
    method! connect _i modname = function
      | [ console ; pclock ; stack ; kv ] ->
        Fmt.strf
          "@[<v 2>\
           match %a with@ \
           | None -> Lwt.return_unit@ \
           | Some server ->@ \
             let port = %a in@ \
             %s.create %s %s %s %s ~hostname:%a ?port server %a %a () >>= function@ \
             | Ok reporter -> Logs.set_reporter reporter; Lwt.return_unit@ \
             | Error e -> invalid_arg e@]"
          pp_key endpoint
          pp_key port
          modname console pclock stack kv
          pp_key hostname
          (opt_int "truncate") config.truncate
          (opt_string "keyname") keyname
      | _ -> failwith (connect_err "syslog tls" 4)
  end

let syslog_tls ?(config = default_syslog_config) ?keyname ?(console = default_console) ?(clock = default_posix_clock) stack kv =
  syslog_tls_conf ?keyname config $ console $ clock $ stack $ kv
