open Mirage

let main = foreign "Handler.Main" (console @-> fs @-> job)

let fat = fat_of_files ~regexp:"*.ml" ()

let () =
  register "fat" [
    main $ default_console $ fat
  ]
