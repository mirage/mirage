open F0

let main = Functoria.(main ~pos:__POS__ "App" job)
let () = register ~src:`None "noop" [ main ]
