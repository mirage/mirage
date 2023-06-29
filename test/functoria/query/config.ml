open F0
open Functoria

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." [ "hello" ] in
  Key.(create "hello" Arg.(opt ~stage:`Run string "Hello World!" doc))

let main =
  Functoria.main ~keys:[ Key.v key ] ~extra_deps:[ dep (app_info ()) ] "App" job

let () = register ~src:`None "noop" [ main ]
