open Functoria
module Name = Functoria_app.Name
open Mirage_impl_misc
module Key = Mirage_key
open Rresult

let gui = job

let gui_qubes = impl @@ object
  inherit base_configurable
  method ty = gui
  val name = Name.ocamlify @@ "gui"
  method name = name
  method module_name = "Qubes.GUI"
  method! packages = Key.pure [ package ~min:"0.4" "mirage-qubes" ]
  method! configure i =
    match get_target i with
    | `Qubes -> R.ok ()
    | _ -> R.error_msg "Qubes GUI invoked for non-Qubes target."
  method! connect _ modname _args =
    Fmt.strf
      "@[<v 2>\
       %s.connect ~domid:0 () >>= fun gui ->@ \
       Lwt.async (fun () -> %s.listen gui);@ \
       Lwt.return (`Ok gui)@]"
      modname modname
end
