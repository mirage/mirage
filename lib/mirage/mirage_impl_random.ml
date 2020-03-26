open Functoria

type random = RANDOM

let random = Type.v RANDOM

let default_random =
  let packages_v =
    Key.match_ Key.(value Mirage_key.target) @@ function
    | #Mirage_key.mode_unix ->
        [ package ~sublibs:[ "unix" ] "mirage-crypto-rng" ]
    | _ -> [ package "mirage-crypto-entropy" ]
  in
  let keys = [ Mirage_key.(v prng) ] in
  let connect i _ _ =
    match Mirage_impl_misc.get_target i with
    | #Mirage_key.mode_unix ->
        "Lwt.return (Mirage_crypto_rng_unix.initialize ())"
    | _ -> "Mirage_crypto_entropy.initialize (module Mirage_crypto_rng.Fortuna)"
  in
  impl ~keys ~packages_v ~connect "Mirage_crypto_rng" random

let nocrypto = Functoria.noop
