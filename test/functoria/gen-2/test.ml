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

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." [ "hello" ] in
  Key.(create "hello" Arg.(opt string "Hello World!" doc))

let test () =
  let i1 = keys sys_argv in
  let i2 = noop in
  let context = Key.empty_context in
  let sigs = job @-> job @-> info @-> job in
  let job =
    main ~keys:[ Key.v key ] "App.Make" sigs $ i1 $ i2 $ app_info ~opam_list ()
  in
  Functoria_test.run ~init:[ i1; i2 ] context job

let () =
  match Action.run (test ()) with Ok () -> () | Error (`Msg e) -> failwith e
