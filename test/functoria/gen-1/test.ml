open Functoria

let opam_list =
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

let test () =
  let context = Key.empty_context in
  let sigs = job @-> info @-> job in
  let job = main "App.Make" sigs $ keys sys_argv $ app_info ~opam_list () in
  Functoria_test.run context job

let () =
  match Action.run (test ()) with Ok () -> () | Error (`Msg e) -> failwith e
