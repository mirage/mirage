open Functoria
module Name = Functoria_app.Name
module Key = Mirage_key
open Rresult

type qrexec = QREXEC
let qrexec = Type QREXEC

let default_qrexec = impl @@ object
  inherit base_configurable
  method ty = qrexec
  val name = Name.ocamlify @@ "qrexec_"
  method name = name
  method module_name = "Qubes.RExec"
  method! packages = Key.pure [ Mirage_impl_qubesdb.pkg ]
  method! configure i =
    match Mirage_impl_misc.get_target i with
    | `Qubes -> R.ok ()
    | _ -> R.error_msg "Qubes remote-exec invoked for non-Qubes target."
  method! connect _ modname _args =
    Fmt.strf
      "@[<v 2>\
       %s.connect ~domid:0 () >>= fun qrexec ->@ \
       Lwt.async (fun () ->@ \
       OS.Lifecycle.await_shutdown_request () >>= fun _ ->@ \
       %s.disconnect qrexec);@ \
       Lwt.return qrexec@]"
      modname modname
end
