open Functoria

let test () =
  let context = Context.empty in
  let sigs = job @-> job in
  let job = main "App.Make" sigs $ runtime_args sys_argv in
  Functoria_test.run context job

let () =
  match Action.run (test ()) with Ok () -> () | Error (`Msg e) -> failwith e
