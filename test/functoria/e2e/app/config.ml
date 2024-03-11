open Functoria
open E2e

let opt = runtime_arg ~pos:__POS__ "App.opt"
let opt_all = runtime_arg ~pos:__POS__ "App.opt_all"
let flag = runtime_arg ~pos:__POS__ "App.flag"
let required = runtime_arg ~pos:__POS__ "App.required"

let runtime_args =
  [ runtime_arg ~pos:__POS__ "App.hello"; runtime_arg ~pos:__POS__ "App.arg" ]

let keys =
  let connect _ _ = function
    | [ opt; opt_all; flag; required ] ->
        code ~pos:__POS__
          {|
      let _ : string = %s
      and _ : string list = %s
      and _ : bool = %s
      and _ : string = %s
      in
      return ()|}
          opt opt_all flag required
    | _ -> failwith "keys: connect needs exactly 4 arguments"
  in
  let runtime_args = [ opt; opt_all; flag; required ] in
  impl ~connect ~runtime_args "Unit" job

let main = main ~runtime_args ~pos:__POS__ "App.Make" (job @-> job)
let () = register "noop" [ main $ keys ]
