(* yiikes *)
let () = Functoria_misc.Codegen.set_main_ml "main.ml"

let ok msg = function
  | Ok () -> ()
  | Error (`Msg e) -> Fmt.failwith "%s: %s" msg e

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

let opam_deps = [
  "base-bigarray", "base";
  "base-threads", "base";
  "base-unix", "base";
  "cmdliner", "1.0.4";
  "conf-m4", "1";
  "dune", "2.0.0";
  "fmt", "0.8.8";
  "ocaml", "4.08.1";
  "ocaml-base-compiler", "4.08.1";
  "ocaml-config", "1";
  "ocamlbuild", "0.14.0";
  "ocamlfind", "1.8.1";
  "seq", "base";
  "stdlib-shims", "0.1.0";
  "topkg", "1.0.1";
]

let test () =
  let context = Functoria_key.empty_context in
  let sigs = Functoria.(job @-> info @-> job) in
  let keys =
    Functoria.(foreign "test" sigs $ keys sys_argv $ app_info ~opam_deps ())
  in
  test_device context keys

let () = test ()
