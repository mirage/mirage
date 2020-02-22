open Rresult
open Functoria

(* yiikes *)
let () =
  Codegen.set_main_ml "main.ml";
  Codegen.append_main "let (>>=) x f = f x";
  Codegen.append_main "let return x = x";
  Codegen.append_main "let run x = x";
  Codegen.newline_main ()

let i1 = Functoria.(keys sys_argv)

let i2 = Functoria.noop

let test_device context device =
  let t = Graph.create device in
  let t = Graph.normalize t in
  let keys = Key.Set.elements (Engine.all_keys t) in
  let packages = Key.eval context (Engine.packages t) in
  let info =
    Functoria.Info.v ~packages ~context ~keys
      ~build_dir:Fpath.(v ".")
      ~build_cmd:[ "build"; "me" ] ~src:`None "foo"
  in
  Engine.configure info t >>= fun () ->
  Engine.connect info ~init:[ i1; i2 ] t;
  Engine.build info t

let opam_deps =
  [
    ("base-bigarray", "base");
    ("base-threads", "base");
    ("base-unix", "base");
    ("cmdliner", "1.0.4");
    ("conf-m4", "1");
    ("dune", "2.0.0");
    ("fmt", "0.8.8");
    ("ocaml", "4.08.1");
    ("ocaml-base-compiler", "4.08.1");
    ("ocaml-config", "1");
    ("ocamlbuild", "0.14.0");
    ("ocamlfind", "1.8.1");
    ("seq", "base");
    ("stdlib-shims", "0.1.0");
    ("topkg", "1.0.1");
  ]

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." [ "hello" ] in
  Key.(create "hello" Arg.(opt string "Hello World!" doc))

let test () =
  let context = Key.empty_context in
  let sigs = Functoria.(job @-> job @-> info @-> job) in
  let keys =
    Functoria.(
      main ~keys:[ Key.abstract key ] "App.Make" sigs
      $ i1
      $ i2
      $ app_info ~opam_deps ())
  in
  test_device context keys

let () = match test () with Ok () -> () | Error (`Msg e) -> failwith e
