open Functoria
open Action.Infix

let prelude () =
  Codegen.set_main_ml "main.ml";
  Codegen.append_main
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
      ~build_dir:(Fpath.v ".") ~src:`None "foo"
  in
  prelude ();
  Engine.configure info t >>= fun () ->
  Engine.connect ?init info t;
  Engine.build info t
