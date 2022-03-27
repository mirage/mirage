open Functoria

type pclock = PCLOCK

let pclock = Type.v PCLOCK

let default_posix_clock =
  let packages_v =
    Mirage_key.(if_ is_unix)
      [ package ~min:"3.0.0" ~max:"5.0.0" "mirage-clock-unix" ]
      [ package ~min:"4.2.0" ~max:"5.0.0" "mirage-clock-solo5" ]
  in
  impl ~packages_v "Pclock" pclock
