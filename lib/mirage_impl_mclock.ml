open Functoria

type mclock = MCLOCK
let mclock = Type MCLOCK

let monotonic_clock_conf = object
  inherit [_] base_configurable
  method ty = mclock
  method name = "mclock"
  method module_name = "Mclock"
  method! packages =
    Mirage_key.(if_ is_unix)
      [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-clock-unix" ]
      [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-clock-freestanding" ]
end

let default_monotonic_clock = impl monotonic_clock_conf
