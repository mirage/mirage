open Mirage

let main = main "App" (job @-> job)
let () = register "noop" [ main $ noop ]
