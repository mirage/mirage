open Mirage

let main = main ~pos:__POS__ "App" job
let () = register ~src:`None "noop" [ if_impl Key.is_solo5 main main ]
