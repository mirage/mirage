open Mirage

let runtime_args = [ runtime_arg ~pos:__POS__ "Unikernel.hello" ]
let main = main ~runtime_args ~pos:__POS__ "App" job
let () = register ~src:`None "noop" [ main ]
