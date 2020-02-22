open Functoria

type random = RANDOM

let random = Type.v RANDOM

let stdlib_random =
  let packages = [ package ~min:"0.1.0" ~max:"1.0.0" "mirage-random-stdlib" ] in
  let connect _ modname _ = Fmt.strf "%s.initialize ()" modname in
  impl ~packages ~connect "Mirage_random_stdlib" random

(* This is to check that entropy is a dependency if "tls" is in
   the package array. *)
let enable_entropy, is_entropy_enabled =
  let r = ref false in
  let f () = r := true in
  let g () = !r in
  (f, g)

let nocrypto =
  let packages =
    [
      package ~min:"0.5.4-2" ~max:"0.6.0" ~sublibs:[ "mirage" ] "nocrypto";
      package ~min:"0.5.0" ~max:"0.6.0" "mirage-entropy";
    ]
  in
  let build _ = Ok (enable_entropy ()) in
  let connect _ _ _ = "Nocrypto_entropy_mirage.initialize ()" in
  impl ~packages ~build ~connect "Nocrypto_entropy" job

let nocrypto_random =
  let packages = [ package ~min:"0.5.4-2" ~max:"0.6.0" "nocrypto" ] in
  let extra_deps = [ abstract nocrypto ] in
  impl ~packages ~extra_deps "Nocrypto.Rng" random

let default_random =
  match_impl
    (Mirage_key.value Mirage_key.prng)
    [ (`Stdlib, stdlib_random); (`Nocrypto, nocrypto_random) ]
    ~default:stdlib_random
