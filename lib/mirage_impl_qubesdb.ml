open Functoria
module Key = Mirage_key
open Mirage_impl_misc
open Rresult

type qubesdb = QUBES_DB
let qubesdb = Type QUBES_DB

let pkg = package ~min:"0.4" ~max:"0.8" "mirage-qubes"

let qubesdb_conf = object
  inherit base_configurable
  method ty = qubesdb
  method name = "qubesdb"
  method module_name = "Qubes.DB"
  method! packages = Key.pure [ pkg ]
  method! configure i =
    match get_target i with
    | `Qubes | `Xen -> R.ok ()
    | _ -> R.error_msg "Qubes DB invoked for an unsupported target; qubes and xen are supported"
  method! connect _ modname _args = Fmt.strf "%s.connect ~domid:0 ()" modname
end

let default_qubesdb = impl qubesdb_conf
