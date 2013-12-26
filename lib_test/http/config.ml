open Mirage

let main = foreign "Handler.Main" (console @-> kv_ro @-> http @-> job)

let fs = crunch "../kv_ro/t"

let http = http_server 8080 (default_ip [tap0])

let () =
  register "http" [
    main $ default_console $ fs $ http
  ]
