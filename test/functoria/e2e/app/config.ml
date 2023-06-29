open Functoria
open E2e

let main = main "App.Make" (job @-> job)
let () = register "noop" [ main $ noop ]
