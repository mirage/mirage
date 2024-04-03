open Functoria
open E2e

let device = main "Unikernel.Make" (job @-> job)
let () = register "in-functor-not-enough" [ device $ noop ]
