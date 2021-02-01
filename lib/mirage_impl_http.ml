open Functoria
open Mirage_impl_pclock
open Mirage_impl_misc
open Mirage_impl_conduit
open Mirage_impl_resolver

type http = HTTP
let http = Type HTTP

type http_client = HTTP_client
let http_client = Type HTTP_client

let cohttp_server = impl @@ object
    inherit base_configurable
    method ty = conduit @-> http
    method name = "http"
    method module_name = "Cohttp_mirage.Server.Make"
    method! packages =
      Mirage_key.pure [ package ~min:"3.0.0" ~max:"4.0.0" "cohttp-mirage" ]
    method! connect _i modname = function
      | [ conduit ] -> Fmt.strf "Lwt.return (%s.listen %s)" modname conduit
      | _ -> failwith (connect_err "http" 1)
  end

let cohttp_server conduit = cohttp_server $ conduit

let cohttp_client = impl @@ object
    inherit base_configurable
    method ty = pclock @-> resolver @-> conduit @-> http_client
    method name = "http_client"
    method module_name = "Cohttp_mirage.Client.Make"
    method! packages =
      Mirage_key.pure [ package ~min:"3.0.0" ~max:"4.0.0" "cohttp-mirage" ]
    method! connect _i modname = function
      | [ _pclock; resolver; conduit ] ->
         Fmt.strf "Lwt.return (%s.ctx %s %s)" modname resolver conduit
      | _ -> failwith (connect_err "http" 2)
  end


let cohttp_client ?(pclock = default_posix_clock) resolver conduit =
  cohttp_client $ pclock $ resolver $ conduit

let httpaf_server conduit = impl @@ object
    inherit base_configurable
    method ty = http
    method name = "httpaf"
    method module_name = "Httpaf_mirage.Server_with_conduit"
    method! packages =
      Mirage_key.pure [ package "httpaf-mirage" ]
    method! deps = [ abstract conduit ]
    method! connect _i modname = function
      | [ conduit ] -> Fmt.strf "%s.connect %s" modname conduit
      | _ -> failwith (connect_err "httpaf" 1)
  end
