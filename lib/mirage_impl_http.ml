open Functoria
open Mirage_impl_misc

type http = HTTP
let http = Type HTTP

let http_server conduit = impl @@ object
    inherit base_configurable
    method ty = http
    method name = "http"
    method module_name = "Cohttp_mirage.Server_with_conduit"
    method! packages = Mirage_key.pure [ package ~min:"1.0.0" "cohttp-mirage" ]
    method! deps = [ abstract conduit ]
    method! connect _i modname = function
      | [ conduit ] -> Fmt.strf "%s.connect %s" modname conduit
      | _ -> failwith (connect_err "http" 1)
  end
