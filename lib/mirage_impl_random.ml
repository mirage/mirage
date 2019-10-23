open Functoria
open Mirage_impl_entry_points

type random = RANDOM
let random = Type RANDOM

let stdlib_random_conf = object
  inherit base_configurable
  method ty = entry_points @-> random
  method name = "random-stdlib"
  method module_name = "Mirage_random_stdlib.Make"
  method! packages = Mirage_key.pure [ package "mirage-random-stdlib" ]
  method! connect _ modname _ = Fmt.strf "%s.initialize ()" modname
end

let stdlib_random_func = impl stdlib_random_conf
let stdlib_random entry_points = stdlib_random_func $ entry_points

(* This is to check that entropy is a dependency if "tls" is in
   the package array. *)
let enable_entropy, is_entropy_enabled =
  let r = ref false in
  let f () = r := true in
  let g () = !r in
  (f, g)

let nocrypto_random_conf = object
  inherit base_configurable
  method ty = entry_points @-> random
  method name = "nocrypto-random"
  method module_name = "Mirage_entropy_nocrypto.Make"
  method! build _ = Rresult.R.ok (enable_entropy ())
  method! packages =
    Mirage_key.pure [ package "mirage-entropy-nocrypto" ]
end

let nocrypto_random_func = impl nocrypto_random_conf
let nocrypto_random (entry_points : entry_points impl) = nocrypto_random_func $ entry_points

let default_random ?(entry_points = default_entry_points) () =
  let random = match_impl (Mirage_key.value Mirage_key.prng)
    [ `Stdlib  , stdlib_random_func
    ; `Nocrypto, nocrypto_random_func ]
    ~default:stdlib_random_func in
  random $ entry_points
