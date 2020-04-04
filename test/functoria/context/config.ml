open F0
open Functoria

let x = Impl.v ~packages:[ package "x" ] "X" job

let y = Impl.v ~packages:[ package "y" ] "Y" job

let target =
  let doc = Key.Arg.info ~doc:"Target." [ "t" ] in
  Key.(create "target" Arg.(opt string "x" doc))

let main = match_impl (Key.value target) ~default:y [ ("x", x) ]

let () = register ~src:`None "noop" [ main ]
