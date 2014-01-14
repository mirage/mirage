open Mirage

let () =
  register "console" [
    foreign "Handler.Main" (console @-> job) $ default_console
  ]
