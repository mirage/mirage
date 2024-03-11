open Functoria

let test () =
  let context = Context.empty in
  let i0 = runtime_args sys_argv in
  let job = main ~pos:__POS__ "App.Make" (job @-> job) $ i0 in
  Functoria_test.run ~project_name:"test" context job

let () =
  match Action.run (test ()) with Ok () -> () | Error (`Msg e) -> failwith e
