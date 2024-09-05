open Functoria.DSL
open Mclock
open Time

type random = RANDOM

let random = typ RANDOM

let rng ?(time = default_time) ?(mclock = default_monotonic_clock) () =
  let packages =
    [ package ~min:"1.0.0" ~max:"2.0.0" "mirage-crypto-rng-mirage" ]
  in
  let connect _ modname _ =
    (* here we could use the boot argument (--prng) to select the RNG! *)
    code ~pos:__POS__ "%s.initialize (module Mirage_crypto_rng.Fortuna)" modname
  in
  impl ~packages ~connect "Mirage_crypto_rng_mirage.Make"
    (Time.time @-> Mclock.mclock @-> random)
  $ time
  $ mclock

let default_random = rng ()
