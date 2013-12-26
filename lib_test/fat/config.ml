open Mirage

let main = foreign "Handler.Main" (console @-> fs @-> job)

let fat = fat (block_of_file "fat.img")

let () =
  register "fat" [
    main $ default_console $ fat
  ]
