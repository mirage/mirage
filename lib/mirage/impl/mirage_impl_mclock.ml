open Functoria
module Key = Mirage_key

type mclock = MCLOCK

let mclock = Type.v MCLOCK

let unix_monotonic_clock =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-clock-unix" ] in
  impl ~packages "Mclock" mclock

let freestanding_monotonic_clock =
  let packages =
    [ package ~min:"3.1.0" ~max:"4.0.0" "mirage-clock-freestanding" ]
  in
  impl ~packages "Mclock" mclock

let default_monotonic_clock =
  match_impl
    Key.(value target)
    [
      (`Unix, unix_monotonic_clock);
      (`Qubes, freestanding_monotonic_clock);
      (`Virtio, freestanding_monotonic_clock);
      (`Hvt, freestanding_monotonic_clock);
      (`Spt, freestanding_monotonic_clock);
      (`Muen, freestanding_monotonic_clock);
      (`Genode, freestanding_monotonic_clock);
      (* TODO(dinosaure): RPi4 *)
    ]
    ~default:unix_monotonic_clock
