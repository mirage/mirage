open Mirage

let test () =
  let context = Key.add_to_context Key.target `Unix Context.empty in
  let sigs = job @-> job in
  let job = main "App.Make" sigs $ keys default_argv in
  Functoria_test.run ~project_name:"mirage"
    ~keys:[ Key.v Key.target ]
    context job

let () =
  match Functoria.Action.run (test ()) with
  | Ok () -> ()
  | Error (`Msg e) -> failwith e
