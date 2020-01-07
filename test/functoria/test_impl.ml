(* yiikes *)
let () = Functoria_misc.Codegen.set_main_ml "main.ml"

let ok msg = function
  | Ok () -> ()
  | Error (`Msg e) -> Alcotest.failf "%s: %s" msg e

let test_device context device =
  let t = Functoria_graph.create device in
  let t = Functoria_graph.normalize t in
  let keys = Functoria_key.Set.elements (Functoria_engine.all_keys t) in
  let packages = Functoria_key.eval context (Functoria_engine.packages t) in
  let info =
    Functoria.Info.create
      ~packages ~context ~keys
      ~name:"foo"
      ~build_dir:Fpath.(v ".")
  in
  Functoria_engine.configure_and_connect ~init:[] info t
  |> ok "configure_and_connect";
  Functoria_engine.build info t
  |> ok "build"

let test () =
  let context = Functoria_key.empty_context in
  let sigs = Functoria.(job @-> info @-> job) in
  let keys = Functoria.(foreign "test" sigs $ keys sys_argv $ app_info ()) in
  test_device context keys

let suite = [
  "keys", `Quick, test;
]
