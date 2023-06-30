open Mirage

let device = generic_stackv4v6 default_network
let main = main "App" (stackv4v6 @-> job)
let () = register ~src:`None "describe" [ main $ device ]
