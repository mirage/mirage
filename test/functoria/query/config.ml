open F0
open Functoria

let main = Functoria.main ~extra_deps:[ dep (app_info ()) ] "App" job
let () = register ~src:`None "noop" [ main ]
