open Functoria.DSL

type mclock = MCLOCK

let mclock = typ MCLOCK

let default_monotonic_clock =
  let packages_v =
    Key.(if_ is_unix)
      [ package ~sublibs:["unix"] "mirage-clock" ]
      [ package ~sublibs:["solo5"] "mirage-clock" ]
  in
  impl ~packages_v "Mclock" mclock
