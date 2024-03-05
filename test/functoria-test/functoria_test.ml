open Functoria
open Action.Syntax

let prelude i =
  Action.with_output ~path:(Info.main i) ~purpose:"init tests" @@ fun ppf ->
  Fmt.pf ppf
    {|(* Geneated by functoria_test *)

let (>>=) x f = f x
let return x = x
let run x = x

|}

let run ?(keys = []) ?init context device =
  let t = Impl.abstract device in
  let t = Impl.simplify ~full:false ~context t in
  let all_keys = Engine.keys t in
  let all_runtime_args = Engine.runtime_args t in
  let keys = keys @ Key.Set.elements all_keys in
  let runtime_args = Runtime_arg.Set.elements all_runtime_args in
  let packages = Key.eval context (Engine.packages t) in
  let info =
    Functoria.Info.v ~packages ~context ~keys ~runtime_args
      ~build_cmd:"build me" ~src:`None "foo"
  in
  let t = Impl.eval ~context t in
  let* () = prelude info in
  let* () = Engine.configure info t in
  Engine.connect ?init info t
