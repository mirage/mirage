open Functoria
module Key = Functoria_key

let warn_error =
  let doc = "Enable -warn-error when compiling OCaml sources." in
  let doc = Key.Arg.info ~docv:"BOOL" ~doc ["warn-error"] in
  let key = Key.Arg.(opt ~stage:`Configure bool false doc) in
  Key.create "warn_error" key

let vote =
  let doc = "Vote." in
  let doc = Key.Arg.info ~docv:"VOTE" ~doc ["vote"] in
  let key = Key.Arg.(opt ~stage:`Configure string "cat" doc) in
  Key.create "vote" key

let main = foreign "App" job

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." ["hello"] in
  Key.(create "hello" Arg.(opt string "Hello World!" doc))

let () = F0.register ~keys:[Key.abstract key] "noop" [main]
