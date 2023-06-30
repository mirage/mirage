open Mirage

let main = main "App" job
let () = register ~src:`None "noop" [ if_impl Key.is_solo5 main main ]
