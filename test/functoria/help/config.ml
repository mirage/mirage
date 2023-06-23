open F0
open Functoria

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." [ "hello" ] in
  Key.(create "hello" Arg.(opt string "Hello World!" doc))

let main = Functoria.main ~keys:[ Key.v key ] "App" job
let () = register ~src:`None "noop" [ main ]
