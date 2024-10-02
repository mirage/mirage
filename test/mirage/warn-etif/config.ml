open Mirage

let eth = etif default_network
let main = main "App.Make" ~pos:__POS__ (Mirage.ethernet @-> job)
let () = register "etif" [ main $ eth ]
