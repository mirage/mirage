open Functoria

type random = RANDOM
let random = Type RANDOM

let stdlib_random_conf = object
  inherit base_configurable
  method ty = random
  method name = "random"
  method module_name = "Mirage_random_stdlib"
  method! packages =
    Mirage_key.pure [ package ~max:"0.1.0" "mirage-random-stdlib" ]
  method! connect _ modname _ = Fmt.strf "%s.initialize ()" modname
end

let stdlib_random = impl stdlib_random_conf

(* This is to check that entropy is a dependency if "tls" is in
   the package array. *)
let enable_entropy, is_entropy_enabled =
  let r = ref false in
  let f () = r := true in
  let g () = !r in
  (f, g)

let nocrypto = impl @@ object
    inherit base_configurable
    method ty = job
    method name = "nocrypto"
    method module_name = "Nocrypto_entropy"
    method! packages =
      Mirage_key.match_ Mirage_key.(value target) @@ function
      | `Unix | `MacOSX ->
        [ package ~min:"0.5.4" ~max:"0.6.0" ~sublibs:["lwt"] "nocrypto" ]
      | _ ->
        [ package ~min:"0.5.4" ~max:"0.6.0" ~sublibs:["mirage"] "nocrypto" ;
          package ~min:"0.4.1" ~max:"0.5.0" "mirage-entropy" ]

    method! build _ = Rresult.R.ok (enable_entropy ())
    method! connect i _ _ =
      match Mirage_impl_misc.get_target i with
      | `Xen | `Qubes | `Virtio | `Hvt | `Muen | `Genode ->
        "Nocrypto_entropy_mirage.initialize ()"
      | `Unix | `MacOSX -> "Nocrypto_entropy_lwt.initialize ()"
  end

let nocrypto_random_conf = object
  inherit base_configurable
  method ty = random
  method name = "random"
  method module_name = "Nocrypto.Rng"
  method! packages =
    Mirage_key.pure [ package ~min:"0.5.4" ~max:"0.6.0" "nocrypto" ]
  method! deps = [abstract nocrypto]
end

let nocrypto_random = impl nocrypto_random_conf

let default_random =
  match_impl (Mirage_key.value Mirage_key.prng) [
    `Stdlib  , stdlib_random;
    `Nocrypto, nocrypto_random;
  ] ~default:stdlib_random
