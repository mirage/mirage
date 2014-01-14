open Mirage

let main = foreign "Handler.Main" (console @-> kv_ro @-> kv_ro @-> job)

let mux = foreign "Multiplex.Make" (kv_ro @-> kv_ro @-> kv_ro)

let x = crunch "../kv_ro/t"

let y = kv_ro_of_fs (fat_of_files ~dir:"../kv_ro/t" ())

let z = mux $ x $ y

let () =
  register "mux" [
    main $ default_console $ y $ z
  ]
