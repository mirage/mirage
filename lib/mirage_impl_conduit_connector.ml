open Functoria
open Mirage_impl_misc
open Mirage_impl_random
open Mirage_impl_stackv4

type conduit_connector = Conduit_connector
let conduit_connector = Type Conduit_connector

let pkg = package ~min:"3.0.1" ~max:"4.0.0" "mirage-conduit"

let tcp_conduit_connector = impl @@ object
    inherit base_configurable
    method ty = stackv4 @-> conduit_connector
    method name = "tcp_conduit_connector"
    method module_name = "Conduit_mirage.With_tcp"
    method! packages = Mirage_key.pure [ pkg ]
    method! connect _ modname = function
      | [ stack ] -> Fmt.strf "Lwt.return (%s.connect %s)@;" modname stack
      | _ -> failwith (connect_err "tcp conduit" 1)
  end

let tls_conduit_connector = impl @@ object
    inherit base_configurable
    method ty = conduit_connector
    method name = "tls_conduit_connector"
    method module_name = "Conduit_mirage"
    method! packages =
      Mirage_key.pure [
        package ~min:"0.10.0" ~max:"0.11.0" ~sublibs:["mirage"] "tls" ;
        pkg
      ]
    method! deps = [ abstract nocrypto ]
    method! connect _ _ _ = "Lwt.return Conduit_mirage.with_tls"
  end
