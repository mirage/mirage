open Mirage

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." [ "hello" ] in
  Key.(create "hello" Arg.(opt string "Hello World!" doc))

let main = main ~keys:[ Key.v key ] "App" (job @-> job)
let () = register "noop" [ main $ noop ]
