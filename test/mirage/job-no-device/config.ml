open Mirage

let main = main "App" job
let () = register ~src:`None "noop" [ main ]
