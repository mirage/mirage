open Functoria
open Mirage_impl_misc

type httpaf = HTTP
let httpaf = Type HTTP

let httpaf_server conduit = impl @@ object
    inherit base_configurable
    method ty = httpaf
    method name = "httpaf"
    method module_name = "Httpaf_mirage.Server_with_conduit"
    method! packages =
      Mirage_key.pure [ package "httpaf-mirage" ]
    method! deps = [ abstract conduit ]
    method! connect _i modname = function
      | [ conduit ] -> Fmt.strf "%s.connect %s" modname conduit
      | _ -> failwith (connect_err "httpaf" 1)
  end
