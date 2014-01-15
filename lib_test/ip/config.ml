open Mirage

let main = foreign "Ping.Main" (console @-> ip @-> job)

let () =
  register "ip" [
    main $ default_console $ default_ip [tap0]
  ]
