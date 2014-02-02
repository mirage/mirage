open Mirage

let basic = foreign "Test.Basic" (console @-> network @-> job)

let () =
  add_to_ocamlfind_libraries ["tcpip.tcpv4";"tcpip.ethif";"tcpip.udpv4";"tcpip.dhcpv4";"mirage-clock-unix"];
  register "manual_ethif" [
    basic $ default_console $ tap0
  ]
