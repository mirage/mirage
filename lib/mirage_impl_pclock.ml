open Functoria

type pclock = PCLOCK
let pclock = Type PCLOCK

let posix_clock_conf = object
  inherit base_configurable
  method ty = pclock
  method name = "pclock"
  method module_name = "Pclock"
  method! packages =
    Mirage_key.(if_ is_unix)
      [ package ~min:"3.0.0" ~max:"5.0.0" "mirage-clock-unix" ]
      [ package ~min:"3.0.0" ~max:"5.0.0" "mirage-clock-freestanding" ]
end

let default_posix_clock = impl posix_clock_conf
