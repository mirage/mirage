open Test_app

let main = Functoria.(foreign "App" job)

let () = register "noop" [main]
