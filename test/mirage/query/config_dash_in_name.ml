open Mirage

let main = main "App" (job @-> job)
let () = register ~src:`None "noop-functor.v0" [ main $ noop ]
