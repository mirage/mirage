open Functoria
open Mirage_impl_misc

type http = HTTP

let http = Type.v HTTP

let connect err _i modname = function
  | [ conduit ] -> Fmt.strf "%s.connect %s" modname conduit
  | _ -> failwith (connect_err err 1)

let cohttp_server conduit =
  let packages = [ package ~min:"2.1.0" ~max:"3.0.0" "cohttp-mirage" ] in
  let extra_deps = [ abstract conduit ] in
  impl ~packages ~connect:(connect "http") ~extra_deps
    "Cohttp_mirage.Server_with_conduit" http

let httpaf_server conduit =
  let packages = [ package "httpaf-mirage" ] in
  let extra_deps = [ abstract conduit ] in
  impl ~packages ~connect:(connect "httapf") ~extra_deps
    "Httpaf_mirage.Server_with_conduit" http
