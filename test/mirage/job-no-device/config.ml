open Mirage

let main = main ~pos:__POS__ "App" job
let () = register ~src:`None "noop" [ main ]
