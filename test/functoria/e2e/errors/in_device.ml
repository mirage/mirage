open Functoria
open E2e

let device =
  let connect _ modname = function
    | [ _; _ ] -> code ~pos:__POS__ "%s.start' () ()" modname
    | _ -> assert false
  in
  impl ~connect "Unikernel.Make" (job @-> job @-> job)

let () = register "my-app" [ device $ noop $ noop ]
