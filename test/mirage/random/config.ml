open Mirage

let main = main "App.Make" ~pos:__POS__ (random @-> job) $ default_random
let () = register "random" [ main ]
