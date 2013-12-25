open Mirage

let main = foreign "Handler.Main" (console @-> kv_ro @-> kv_ro @-> job)

let () =
  register "kv_ro" [
    main $ default_console $ crunch "t" $ crunch "t"
  ]
