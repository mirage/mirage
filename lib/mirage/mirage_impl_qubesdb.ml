open Functoria
module Key = Mirage_key
open Mirage_impl_misc

type qubesdb = QUBES_DB

let qubesdb = Type.v QUBES_DB

let pkg = package ~min:"0.8.0" ~max:"0.9.0" "mirage-qubes"

let default_qubesdb =
  let packages = [ pkg ] in
  let configure i =
    match get_target i with
    | `Qubes | `Xen -> Ok ()
    | _ ->
        failwith
          "Qubes DB invoked for an unsupported target; qubes and xen are \
           supported"
  in
  let connect _ modname _args = Fmt.strf "%s.connect ~domid:0 ()" modname in
  impl ~packages ~configure ~connect "Qubes.DB" qubesdb
