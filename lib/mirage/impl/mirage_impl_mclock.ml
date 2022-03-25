open Functoria

type mclock = MCLOCK

let mclock = Type.v MCLOCK

let default_monotonic_clock =
  let packages_v =
    Mirage_key.(if_ is_unix)
      [ package ~min:"4.1.0" ~max:"5.0.0" "mirage-clock-unix" ]
      [ package ~min:"4.2.0" ~max:"5.0.0" "mirage-clock-solo5" ]
  in
  impl ~packages_v "Mclock" mclock
