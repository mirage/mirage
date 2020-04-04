open Functoria
open Action.Infix

let prelude i =
  Action.with_output ~path:(Info.main i) ~purpose:"init tests" @@ fun ppf ->
  Fmt.pf ppf
    {|(* Geneated by functoria_test *)

let (>>=) x f = f x
let return x = x
let run x = x

|}

let run ?(keys = []) ?init context device =
  let t = Graph.create device in
  let t = Graph.eval ~context t in
  let keys = keys @ Key.Set.elements (Engine.all_keys t) in
  let packages = Key.eval context (Engine.packages t) in
  let info =
    Functoria.Info.v ~packages ~context ~keys ~build_cmd:[ "build"; "me" ]
      ~src:`None "foo"
  in
  prelude info >>= fun () ->
  Engine.configure info t >>= fun _ ->
  Engine.connect ?init info t >>= fun () -> Engine.build info t
