open Functoria
open Mirage_impl_stack
open Mirage_impl_misc
open Mirage_impl_random

type conduit = Conduit
let conduit = Type Conduit

let pkg = package ~min:"5.0.0" ~max:"6.0.0" "conduit-mirage"

let tcp = impl @@ object
    inherit base_configurable
    method ty = stackv4v6 @-> conduit
    method name = Functoria_app.Name.create "conduit_tcp" ~prefix:"conduit_tcp"
    method module_name = "Conduit_mirage.TCP"
    method! packages = Mirage_key.pure [ pkg ]
    method! connect _i _ = function
      | [ stack ] -> Fmt.strf "Lwt.return %s@;" stack
      | _ -> failwith (connect_err "tcp_conduit" 1)
  end

let tls random = impl @@ object
    inherit base_configurable
    method ty = conduit @-> conduit
    method name = Functoria_app.Name.create "conduit_tls" ~prefix:"conduit_tls"
    method module_name = "Conduit_mirage.TLS"
    method! deps = [ abstract random ]
    method! packages =
      Mirage_key.pure [
          package ~min:"0.13.0" ~max:"0.16.0" "tls-mirage"; pkg]
    method! connect _i _ = function
      | [ stack; _random ] -> Fmt.strf "Lwt.return %s@;" stack
      | _ -> failwith (connect_err "tls_conduit" 1)
  end

let conduit_direct ?tls:(use_tls=false) ?(random=default_random) s =
  if use_tls then tls random $ (tcp $ s)
  else tcp $ s
