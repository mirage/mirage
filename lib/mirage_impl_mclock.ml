open Functoria

type mclock = MCLOCK

let mclock = Type.v MCLOCK

let default_monotonic_clock =
  let packages_v =
    Mirage_key.(if_ is_unix)
      [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-clock-unix" ]
      [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-clock-freestanding" ]
  in
  impl ~packages_v "Mclock" mclock
