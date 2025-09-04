open Cmdliner

let pf = Format.fprintf
let str = Format.asprintf

let pp_group ppf = function
  | None -> pf ppf "the unikernel"
  | Some s -> pf ppf "the %s group" s

let runtime_arg ?(group = "") ~docs ?docv ~doc ~default c name =
  let prefix = if group = "" then group else group ^ "-" in
  let doc = Arg.info ~docs ?docv ~doc [ prefix ^ name ] in
  Arg.(value & opt c default doc)

let interface ?group ?(docs = Mirage_runtime.s_net) default =
  let doc = str "The network interface listened by %a." pp_group group in
  runtime_arg ~doc ~default ?group ~docs ~docv:"INTERFACE" Arg.string
    "interface"

module Conv = struct
  let conv of_string to_string : _ Cmdliner.Arg.conv =
    let pp ppf v = Format.pp_print_string ppf (to_string v) in
    Cmdliner.Arg.conv (of_string, pp)

  let ipv4_address = conv Ipaddr.V4.of_string Ipaddr.V4.to_string
  let ipv4 = conv Ipaddr.V4.Prefix.of_string Ipaddr.V4.Prefix.to_string
  let ipv6_address = conv Ipaddr.V6.of_string Ipaddr.V6.to_string
  let ipv6 = conv Ipaddr.V6.Prefix.of_string Ipaddr.V6.Prefix.to_string
  let ip_address = conv Ipaddr.of_string Ipaddr.to_string
end

open Conv

module V4 = struct
  let network ?group ?(docs = Mirage_runtime.s_net) default =
    let doc =
      str
        "The network of %a specified as an IP address and netmask, e.g. \
         192.168.0.1/16 ."
        pp_group group
    in
    runtime_arg ~doc ~docs ~docv:"PREFIX" ~default ?group ipv4 "ipv4"

  let gateway ?group ?(docs = Mirage_runtime.s_net) default =
    let doc = str "The gateway of %a." pp_group group in
    runtime_arg ~doc ~docs ~docv:"IP" ~default ?group
      Arg.(some ipv4_address)
      "ipv4-gateway"
end

module V6 = struct
  let network ?group ?(docs = Mirage_runtime.s_net) default =
    let doc =
      str "The network of %a specified as IPv6 address and prefix length."
        pp_group group
    in
    runtime_arg ~doc ~docs ~docv:"PREFIX" ~default ?group Arg.(some ipv6) "ipv6"

  let gateway ?group ?(docs = Mirage_runtime.s_net) default =
    let doc = str "The gateway of %a." pp_group group in
    runtime_arg ~doc ~docs ~docv:"IP" ~default ?group
      Arg.(some ipv6_address)
      "ipv6-gateway"

  let accept_router_advertisements ?group ?(docs = Mirage_runtime.s_net) () =
    let doc = str "Accept router advertisements for %a." pp_group group in
    runtime_arg ~doc ~docs ?group ~default:true Arg.bool
      "accept-router-advertisements"
end

let ipv4_only ?group ?(docs = Mirage_runtime.s_net) () =
  let doc = str "Only use IPv4 for %a." pp_group group in
  runtime_arg ~doc ~docs ?group ~default:false Arg.bool "ipv4-only"

let ipv6_only ?group ?(docs = Mirage_runtime.s_net) () =
  let doc = str "Only use IPv6 for %a." pp_group group in
  runtime_arg ~doc ~docs ?group ~default:false Arg.bool "ipv6-only"

let resolver ?group ?(docs = Mirage_runtime.s_net) ?default () =
  let doc = str "DNS resolver (default to anycast.censurfridns.dk)" in
  runtime_arg ~doc ~docv:"IP" ~docs ?group ~default
    Arg.(some (list string))
    "resolver"

let dns_servers ?group ?(docs = Mirage_runtime.s_dns) default =
  let doc = str "DNS servers (default to anycast.censurfridns.dk)" in
  runtime_arg ~doc ~docv:"DNS-SERVER" ~docs ?group ~default
    Arg.(some (list string))
    "dns_servers"

let dns_timeout ?group ?(docs = Mirage_runtime.s_dns) default =
  let doc = str "DNS timeout (in nanoseconds)" in
  runtime_arg ~doc ~docv:"DNS-TIMEOUT" ~docs ?group ~default
    Arg.(some int64)
    "dns_timeout"

let dns_cache_size ?group ?(docs = Mirage_runtime.s_dns) default =
  let doc = str "DNS cache size" in
  runtime_arg ~doc ~docv:"DNS-CACHE-SIZE" ~docs ?group ~default
    Arg.(some int)
    "dns_cache_size"

let he_aaaa_timeout ?group ?(docs = Mirage_runtime.s_he) default =
  let doc = str "AAAA timeout (in nanoseconds)" in
  runtime_arg ~doc ~docv:"AAAA-TIMEOUT" ~docs ?group ~default
    Arg.(some int64)
    "he_aaaa_timeout"

let he_connect_delay ?group ?(docs = Mirage_runtime.s_he) default =
  let doc = str "Delay (in nanoseconds) for connection establishment" in
  runtime_arg ~doc ~docv:"CONNECT-DELAY" ~docs ?group ~default
    Arg.(some int64)
    "he_connect_delay"

let he_connect_timeout ?group ?(docs = Mirage_runtime.s_he) default =
  let doc = str "Connection establishment timeout (in nanoseconds)" in
  runtime_arg ~doc ~docv:"CONNECT-TIMEOUT" ~docs ?group ~default
    Arg.(some int64)
    "he_connect_timeout"

let he_resolve_timeout ?group ?(docs = Mirage_runtime.s_he) default =
  let doc = str "DNS resolution timeout (in nanoseconds)" in
  runtime_arg ~doc ~docv:"RESOLVE-TIMEOUT" ~docs ?group ~default
    Arg.(some int64)
    "he_resolve_timeout"

let he_resolve_retries ?group ?(docs = Mirage_runtime.s_he) default =
  let doc = str "Amount of DNS resolution attempts" in
  runtime_arg ~doc ~docv:"RESOLVE-RETRIES" ~docs ?group ~default
    Arg.(some int)
    "he_resolve_retries"

let he_timer_interval ?group ?(docs = Mirage_runtime.s_he) default =
  let doc = str "Interal (in nanoseconds) for execution of the timer" in
  runtime_arg ~doc ~docv:"TIMER-INTERVAL" ~docs ?group ~default
    Arg.(some int64)
    "he_timer_interval"

let ssh_key ?group ?(docs = Mirage_runtime.s_ssh) default =
  let doc = str "Private SSH key (rsa:<seed> or ed25519:<b64-key>)." in
  runtime_arg ~doc ~docs ~docv:"KEY" ?group ~default Arg.(some string) "ssh-key"

let ssh_password ?group ?(docs = Mirage_runtime.s_ssh) default =
  let doc = str "Private SSH password." in
  runtime_arg ~doc ~docs ~docv:"PASSWORD" ?group ~default
    Arg.(some string)
    "ssh-password"

let ssh_authenticator ?group ?(docs = Mirage_runtime.s_ssh) default =
  let doc = str "SSH authenticator." in
  runtime_arg ~doc ~docs ~docv:"SSH-AUTHENTICATOR" ?group ~default
    Arg.(some string)
    "ssh-authenticator"

let tls_authenticator ?group ?(docs = Mirage_runtime.s_tls) default =
  let doc = str "TLS authenticator." in
  runtime_arg ~doc ~docs ~docv:"TLS-AUTHENTICATOR" ?group ~default
    Arg.(some string)
    "tls-authenticator"

let http_headers ?group ?(docs = Mirage_runtime.s_http) default =
  let doc = str "HTTP headers." in
  runtime_arg ~doc ~docs ~docv:"HEADERS" ?group ~default
    Arg.(some (list ~sep:',' (pair ~sep:':' string string)))
    "http-headers"

let syslog ?group ?(docs = Mirage_runtime.s_log) default =
  let doc = str "syslog server IP" in
  runtime_arg ~doc ~docv:"IP" ~docs ?group ~default
    Arg.(some ip_address)
    "syslog"

let syslog_port ?group ?(docs = Mirage_runtime.s_log) default =
  let default = Option.value ~default:514 default in
  let doc = str "syslog server port" in
  runtime_arg ~doc ~docs ~docv:"PORT" ?group ~default Arg.int "syslog-port"

let syslog_truncate ?group ?(docs = Mirage_runtime.s_log) default =
  let doc = str "truncate syslog messages" in
  runtime_arg ~doc ~docs ?group ~default Arg.(some int) "syslog-truncate"

let syslog_keyname ?group ?(docs = Mirage_runtime.s_log) default =
  let doc = str "TLS key name used for syslog" in
  runtime_arg ~doc ~docs ?group ~default Arg.(some string) "syslog-keyname"

let monitor ?group ?(docs = Mirage_runtime.s_log) default =
  let doc = str "monitor server" in
  runtime_arg ~doc ~docv:"IP" ~docs ?group ~default
    Arg.(some ip_address)
    "monitor"

module Arg = Conv
