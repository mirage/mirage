open Functoria
open E2e

let opt : string runtime_arg = Runtime_arg.create "App.opt"
let opt_all : string list runtime_arg = Runtime_arg.create "App.opt_all"
let flag : bool runtime_arg = Runtime_arg.create "App.flag"
let required : string runtime_arg = Runtime_arg.create "App.required"

let keys =
  let connect _ _ _ =
    code ~pos:__POS__
      {|
      let _ : string = %a
      and _ : string list = %a
      and _ : bool = %a
      and _ : string = %a
      in
      return ()|}
      Runtime_arg.call opt Runtime_arg.call opt_all Runtime_arg.call flag
      Runtime_arg.call required
  in
  let runtime_args = Runtime_arg.[ v opt; v opt_all; v flag; v required ] in
  impl ~connect ~runtime_args "Unit" job

let main = main "App.Make" (job @-> job)
let () = register "noop" [ main $ keys ]
