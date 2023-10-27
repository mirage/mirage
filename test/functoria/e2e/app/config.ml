open Functoria
open E2e

let opt : string runtime_key = Runtime_key.create "App.opt"
let opt_all : string list runtime_key = Runtime_key.create "App.opt_all"
let flag : bool runtime_key = Runtime_key.create "App.flag"
let required : string runtime_key = Runtime_key.create "App.required"

let keys =
  let connect _ _ _ =
    Fmt.str
      {|
      let _ : string = %a
      and _ : string list = %a
      and _ : bool = %a
      and _ : string = %a
      in
      return ()|}
      Runtime_key.call opt Runtime_key.call opt_all Runtime_key.call flag
      Runtime_key.call required
  in
  let runtime_keys = Runtime_key.[ v opt; v opt_all; v flag; v required ] in
  impl ~connect ~runtime_keys "Unit" job

let main = main "App.Make" (job @-> job)
let () = register "noop" [ main $ keys ]
