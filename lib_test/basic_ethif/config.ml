open Mirage

let basic = foreign "Test.Basic" (console @-> network @-> job)

let () =
  add_to_ocamlfind_libraries ["tcpip.ethif"; "tcpip.udpv4"; "tcpip.ipv4"; "tcpip.tcpv4"; "tcpip.dhcp"];
  register "basic_ethif" [
    basic $ default_console $ tap0
  ]
