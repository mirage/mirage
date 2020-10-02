open Functoria
open Mirage_impl_misc
open Mirage_impl_stackv4

type c_tcp
type c_tls

type 'a conduit = Conduit
type tcp_conduit = c_tcp conduit
type tls_conduit = c_tls conduit

let conduit = Type Conduit
let tcp_conduit: tcp_conduit typ = conduit
let tls_conduit: tls_conduit typ = conduit

let bounded_conduit_package ?sublibs name =
  package ~min:"3.0.0" ~max:"4.0.0" ?sublibs name

let pkg sublibs =
  bounded_conduit_package ~sublibs "conduit-mirage"

let tcp_conduit_conf = impl @@ object
    inherit base_configurable
    method ty = stackv4 @-> tcp_conduit
    method name = "tcp_conduit"
    method module_name = "Conduit_mirage_tcp.Make"
    method! packages = Mirage_key.pure [ pkg ["tcp"] ]
    method! connect _ modname = function
      | [ _ ] ->
        Fmt.strf "Lwt.return (%s.protocol, %s.service)@;" modname modname
      | _ -> failwith (connect_err "tcp conduit" 1)
  end

let create_tcp_conduit stack =
  tcp_conduit_conf $ stack

let tls_conduit_conf conduit = impl @@ object
    inherit base_configurable
    method ty = tls_conduit
    method name = "tls_conduit"
    method module_name = "Conduit_tls.Make(Conduit_mirage.IO)(Conduit_mirage)"
    method! packages =
      Mirage_key.pure [
        bounded_conduit_package "conduit-tls";
        pkg ["tcp"]
      ]
    method! deps = [ abstract conduit ]
    method! connect _ modname = function
      | [ conduit ] ->
        Fmt.strf
          "let tls = %s.protocol_with_tls (fst %s) in@.\
           Lwt.return (tls, %s.service_with_tls (snd %s) tls)@;"
          modname conduit modname conduit
      | _ -> failwith (connect_err "tls conduit" 1)
  end

let create_tls_conduit conduit = tls_conduit_conf conduit
