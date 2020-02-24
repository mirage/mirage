open Functoria

type random = RANDOM
let random = Type RANDOM

let random_conf = object
  inherit base_configurable
  method ty = random
  method name = "random"
  method module_name = "Mirage_crypto_rng"
  method! packages =
    Mirage_key.pure [
      package "mirage-crypto-rng" ;
      package ~min:"1.0.0" "mirage-entropy" ;
    ]
  method! connect _ _ _ =
    (* here we could use the boot argument to select the RNG! *)
    "Entropy.connect (module Mirage_crypto_rng.Fortuna)"
end

let default_random = impl random_conf

let nocrypto = Functoria_app.noop
