open Functoria

let test () =
  let i1 = runtime_args sys_argv in
  let i2 = noop in
  let context = Context.empty in
  let sigs = job @-> job @-> job in
  let job = main ~pos:__POS__ "App.Make" sigs $ i1 $ i2 in
  Functoria_test.run ~init:[ i1; i2 ] context job

let () =
  match Action.run (test ()) with Ok () -> () | Error (`Msg e) -> failwith e
