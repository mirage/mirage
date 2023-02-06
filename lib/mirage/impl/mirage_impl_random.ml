open Functoria
open Mirage_impl_mclock
open Mirage_impl_time

type random = RANDOM

let random = Type.v RANDOM

let rng ?(time = default_time) ?(mclock = default_monotonic_clock) () =
  let packages =
    [
      package ~min:"0.8.0" ~max:"0.12.0" "mirage-crypto-rng-mirage";
      package ~min:"3.0.0" ~max:"4.0.0" "mirage-random";
    ]
  in
  let connect _ modname _ =
    (* here we could use the boot argument (--prng) to select the RNG! *)
    Fmt.str "%s.initialize (module Mirage_crypto_rng.Fortuna)" modname
  in
  impl ~packages ~connect "Mirage_crypto_rng_mirage.Make"
    (Mirage_impl_time.time @-> Mirage_impl_mclock.mclock @-> random)
  $ time
  $ mclock

let default_random = rng ()
