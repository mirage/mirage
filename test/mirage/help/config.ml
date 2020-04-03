open Mirage

let main = main "App" job

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." [ "hello" ] in
  Key.(create "hello" Arg.(opt string "Hello World!" doc))

let () = register ~keys:[ Key.v key ] ~src:`None "noop" [ main ]
