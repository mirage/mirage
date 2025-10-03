open E2e
open Functoria
open Cmdliner

let x = Impl.v ~packages:[ package "x" ] "X" job
let y = Impl.v ~packages:[ package "y" ] "Y" job

let target_conv : [ `X | `Y ] Cmdliner.Arg.conv =
  Cmdliner.Arg.enum [ ("y", `Y); ("x", `X) ]

let target =
  let doc = Arg.info ~doc:"Target." [ "t" ] in
  let key = Key.Arg.opt target_conv `X doc in
  Key.create "target" key

let main = match_impl (Key.value target) ~default:y [ (`X, x) ]
let () = register ~src:`None "noop" [ main ]
