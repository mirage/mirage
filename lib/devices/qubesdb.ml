open Functoria.DSL
open Functoria.Action

type qubesdb = QUBES_DB

let qubesdb = typ QUBES_DB
let pkg = package ~min:"2.0.0" ~max:"3.0.0" "mirage-qubes"

let default_qubesdb =
  let packages = [ pkg ] in
  let configure i =
    match Misc.get_target i with
    | `Qubes | `Xen -> ok ()
    | _ ->
        error
          "Qubes DB invoked for an unsupported target; qubes and xen are \
           supported"
  in
  let connect _ modname _args =
    code ~pos:__POS__ "%s.connect ~domid:0 ()" modname
  in
  impl ~packages ~configure ~connect "Qubes.DB" qubesdb
