open F0
open Functoria

let main = Functoria.main "App" job
let () = register ~src:`None "noop" [ main ]
