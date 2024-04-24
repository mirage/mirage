open Functoria.DSL
open Mclock
open Time

type random = RANDOM

let random = typ RANDOM

let rng =
  let packages =
    [
      package ~min:"0.8.0" ~max:"0.12.0" "mirage-crypto-rng-mirage";
    ]
  in
  let connect _ modname _ =
    (* here we could use the boot argument (--prng) to select the RNG! *)
    code ~pos:__POS__ "%s.initialize (module Mirage_crypto_rng.Fortuna)" modname
  in
  impl
    ~extra_deps:[dep default_time ; dep default_monotonic_clock]
    ~packages ~connect "Mirage_crypto_rng_mirage" random

let default_random = rng
