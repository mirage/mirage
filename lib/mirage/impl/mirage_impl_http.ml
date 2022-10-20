open Functoria
open Mirage_impl_pclock
open Mirage_impl_misc
open Mirage_impl_conduit
open Mirage_impl_resolver
open Mirage_impl_tcp

type http = HTTP

let http = Type.v HTTP

type http_client = HTTP_client

let http_client = Type.v HTTP_client

let connect err _i modname = function
  | [ conduit ] -> Fmt.str "Lwt.return (%s.listen %s)" modname conduit
  | _ -> failwith (connect_err err 1)

let cohttp_server =
  let packages = [ package ~min:"4.0.0" ~max:"6.0.0" "cohttp-mirage" ] in
  impl ~packages ~connect:(connect "http") "Cohttp_mirage.Server.Make"
    (conduit @-> http)

let cohttp_server conduit = cohttp_server $ conduit

let cohttp_client =
  let packages = [ package ~min:"4.0.0" ~max:"6.0.0" "cohttp-mirage" ] in
  let connect _i modname = function
    | [ _pclock; resolver; conduit ] ->
        Fmt.str "Lwt.return (%s.ctx %s %s)" modname resolver conduit
    | _ -> failwith (connect_err "http" 2)
  in
  impl ~packages ~connect "Cohttp_mirage.Client.Make"
    (pclock @-> resolver @-> conduit @-> http_client)

let cohttp_client ?(pclock = default_posix_clock) resolver conduit =
  cohttp_client $ pclock $ resolver $ conduit

let httpaf_server conduit =
  let packages = [ package "httpaf-mirage" ] in
  let extra_deps = [ dep conduit ] in
  impl ~packages ~connect:(connect "httpaf") ~extra_deps
    "Httpaf_mirage.Server_with_conduit" http

type http_server = HTTP_server

let http_server = Type.v HTTP_server

let paf_server port =
  let connect _ modname = function
    | [ tcpv4v6 ] ->
        Fmt.str {ocaml|%s.init ~port:%a %s|ocaml} modname Key.serialize_call
          (Key.v port) tcpv4v6
    | _ -> assert false
  in
  let packages =
    [ package "paf" ~sublibs:[ "mirage" ] ~min:"0.3.0" ~max:"0.4.0" ]
  in
  let keys = [ Key.v port ] in
  impl ~connect ~packages ~keys "Paf_mirage.Make" (tcpv4v6 @-> http_server)
