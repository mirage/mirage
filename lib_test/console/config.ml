open Mirage

let key =
  Key.(create
    ~doc:"The string used to say hello."
    ~default:"hello."
    "hello"
    Desc.string
  )

let () =
  register
    ~keys:[Key.V key]
    "console" [
    foreign "Handler.Main" (console @-> job) $ default_console
  ]
