open Mirage

let main = foreign "Handler.Main" (console @-> kv_ro @-> http @-> job)

let fs = kv_ro_of_fs (fat_of_files ~dir:"../kv_ro/t" ())

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

let stack console =
  match net, dhcp with
  | `Direct, true  -> direct_stackv4_with_dhcp console tap0
  | `Direct, false -> direct_stackv4_with_default_ipv4 console tap0
  | `Socket, _     -> socket_stackv4 console [Ipaddr.V4.any]

let () =
  register "http" [
    main $ default_console $ fs $ http_server 8080 (stack default_console)
  ]
