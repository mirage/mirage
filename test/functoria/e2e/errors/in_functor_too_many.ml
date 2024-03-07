open Functoria
open E2e

let device = main "Unikernel.Make" (job @-> job @-> job @-> job)
let () = register "my-app" [ device $ noop $ noop $ noop ]
