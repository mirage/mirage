open Mirage

let basic = foreign "Test.Main" (console @-> stackv4 @-> job)

let net =
  try match Sys.getenv "NET" with
    | "direct" -> `Direct
    | "socket" -> `Socket
    | _        -> `Direct
  with Not_found -> `Direct

let dhcp =
  try match Sys.getenv "DHCP" with
    | "" -> false
    | _  -> true
  with Not_found -> false

let stack =
  match net, dhcp with
  | `Direct, true  -> direct_stackv4_with_dhcp default_console tap0
  | `Direct, false -> direct_stackv4_with_default_ipv4 default_console tap0
  | `Socket, _     -> socket_stackv4 default_console [Ipaddr.V4.any]

let () = match net with
  | `Direct -> add_to_ocamlfind_libraries ["tcpip.stack-direct"]
  | `Socket -> add_to_ocamlfind_libraries ["tcpip.stack-socket"]

let () =
  add_to_opam_packages ["mirage-http"];
  add_to_ocamlfind_libraries ["mirage-http"];
  register "basic_http" [
    basic $ default_console $ stack;
  ]
