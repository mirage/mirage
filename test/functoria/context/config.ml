open F0
open Functoria

let x = Impl.v ~packages:[ package "x" ] "X" job
let y = Impl.v ~packages:[ package "y" ] "Y" job

let target_conv : _ Cmdliner.Arg.conv =
  let parser, printer = Cmdliner.Arg.enum [ ("y", `Y); ("x", `X) ] in
  (parser, printer)

let target_serialize ppf = function
  | `Y -> Fmt.pf ppf "`Y"
  | `X -> Fmt.pf ppf "`X"

let target =
  let conv' =
    Key.Arg.conv ~conv:target_conv ~runtime_conv:"target"
      ~serialize:target_serialize
  in
  let doc = Key.Arg.info ~doc:"Target." [ "t" ] in
  Key.(create "target" Arg.(opt conv' `X doc))

let main = match_impl (Key.value target) ~default:y [ (`X, x) ]
let () = register ~src:`None "noop" [ main ]
