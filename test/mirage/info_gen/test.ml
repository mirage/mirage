open Mirage

let test () =
  let context = Key.add_to_context Key.target `Unix Key.empty_context in
  let sigs = job @-> info @-> job in
  let job =
    main "App.Make" sigs $ keys default_argv $ app_info_with_opam_deps []
  in
  Functoria_test.run ~keys:[ Key.v Key.target ] context job

let () =
  match Functoria.Action.run (test ()) with
  | Ok () -> ()
  | Error (`Msg e) -> failwith e
