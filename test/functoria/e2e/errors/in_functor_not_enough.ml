open Functoria
open E2e

let device = main "Unikernel.Make" (job @-> job)
let () = register "my-app" [ device $ noop ]
