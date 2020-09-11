open F0
open Functoria

let extra_deps = [ dep (app_info ()) ]

let main = Functoria.(main ~extra_deps "App" job)

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." [ "hello" ] in
  Key.(create "hello" Arg.(opt string "Hello World!" doc))

let () = register ~keys:[ Key.v key ] "noop" [ main ]
