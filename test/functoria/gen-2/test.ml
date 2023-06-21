open Functoria

let key =
  let doc = Key.Arg.info ~doc:"How to say hello." [ "hello" ] in
  Key.(create "hello" Arg.(opt string "Hello World!" doc))

let test () =
  let i1 = keys sys_argv in
  let i2 = noop in
  let context = Key.empty_context in
  let sigs = job @-> job @-> job in
  let job =
    main ~keys:[ Key.v key ] "App.Make" sigs $ i1 $ i2
  in
  Functoria_test.run ~init:[ i1; i2 ] context job

let () =
  match Action.run (test ()) with Ok () -> () | Error (`Msg e) -> failwith e
