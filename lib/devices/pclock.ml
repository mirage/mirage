open Functoria.DSL

type pclock = PCLOCK

let pclock = typ PCLOCK

let default_posix_clock =
  let packages_v =
    Key.(if_ is_unix)
      [ package ~sublibs:["unix"] "mirage-clock" ]
      [ package ~sublibs:["solo5"] "mirage-clock" ]
  in
  impl ~packages_v "Pclock" pclock
