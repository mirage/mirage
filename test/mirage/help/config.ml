open Mirage

let main = main ~pos:__POS__ "App" (job @-> job)
let () = register "noop" [ main $ noop ]
