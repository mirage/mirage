open Mirage

let main = foreign "Ping.Main" (console @-> network @-> job)

let () =
  add_to_opam_packages ["tcpip"];
  add_to_ocamlfind_libraries ["tcpip.ethif"];
  register "ip" [
    main $ default_console $ tap0
  ]
