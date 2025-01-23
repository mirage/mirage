open Mirage

let main = main "App.Make" ~pos:__POS__ (job @-> job) $ noop
let () = register "random" [ main ]
