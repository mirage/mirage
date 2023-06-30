open F0

let main = Functoria.(main "App" job)
let () = register ~src:`None "noop" [ main ]
