open Mirage

let main = foreign "Handler.Main" (console @-> kv_ro @-> http @-> job)

let fs = kv_ro_of_fs (fat (block_of_file "fat.img"))

let http = http_server 8080 (default_ip [tap0])

let () =
  register "http" [
    main $ default_console $ fs $ http
  ]
