open Functoria
open Mirage_impl_mclock
open Mirage_impl_time

type random = RANDOM
let random = Type RANDOM

let random_conf = object
  inherit base_configurable
  method ty = time @-> mclock @-> random
  method name = "random"
  method module_name = "Mirage_crypto_rng_mirage.Make"
  method! keys = [ Mirage_key.(abstract prng) ]
  method! packages =
    Mirage_key.pure [
      package ~sublibs:["mirage"] ~min:"0.7.0" "mirage-crypto-rng"
    ]
  method! connect _i modname _ =
    (* here we could use the boot argument (--prng) to select the RNG! *)
    Fmt.strf "%s.initialize (module Mirage_crypto_rng.Fortuna)" modname
end

let default_random = impl random_conf $ default_time $ default_monotonic_clock

let nocrypto = Functoria_app.noop
