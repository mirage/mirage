open Functoria.DSL

type http = HTTP

let http = typ HTTP

type http_client = HTTP_client

let http_client = typ HTTP_client

let connect err _i modname = function
  | [ conduit ] -> code ~pos:__POS__ "Lwt.return (%s.listen %s)" modname conduit
  | _ -> Misc.connect_err err 1

let cohttp_server =
  let packages = [ package ~min:"6.1.0" ~max:"7.0.0" "cohttp-mirage" ] in
  impl ~packages ~connect:(connect "http") "Cohttp_mirage.Server.Make"
    (Conduit.conduit @-> http)

let cohttp_server conduit = cohttp_server $ conduit

let cohttp_client =
  let packages = [ package ~min:"6.1.0" ~max:"7.0.0" "cohttp-mirage" ] in
  let connect _i modname = function
    | [ resolver; conduit ] ->
        code ~pos:__POS__ "Lwt.return (%s.ctx %s %s)" modname resolver conduit
    | _ -> Misc.connect_err "http" 2
  in
  impl ~packages ~connect "Cohttp_mirage.Client.Make"
    (Resolver.resolver @-> Conduit.conduit @-> http_client)

let cohttp_client resolver conduit = cohttp_client $ resolver $ conduit

let httpaf_server conduit =
  let packages = [ package "httpaf-mirage" ] in
  let extra_deps = [ dep conduit ] in
  impl ~packages ~connect:(connect "httpaf") ~extra_deps
    "Httpaf_mirage.Server_with_conduit" http

type http_server = HTTP_server

let http_server = typ HTTP_server

let paf_server port =
  let connect _ modname = function
    | [ tcpv4v6; port ] ->
        code ~pos:__POS__ {ocaml|%s.init ~port:%s %s|ocaml} modname port tcpv4v6
    | _ -> Misc.connect_err "paf_server" 2
  in
  let packages =
    [ package "paf" ~sublibs:[ "mirage" ] ~min:"0.8.0" ~max:"0.9.0" ]
  in
  let runtime_args = Runtime_arg.[ v port ] in
  impl ~connect ~packages ~runtime_args "Paf_mirage.Make"
    (Tcp.tcpv4v6 @-> http_server)

type alpn_client = ALPN_client

let alpn_client = typ ALPN_client

let paf_client =
  let packages = [ package "http-mirage-client" ~min:"0.0.9" ~max:"0.1.0" ] in
  let connect _ modname = function
    | [ _tcpv4v6; ctx ] ->
        code ~pos:__POS__ {ocaml|%s.connect %s|ocaml} modname ctx
    | _ -> Misc.connect_err "paf_client" 2
  in
  impl ~connect ~packages "Http_mirage_client.Make"
    (Tcp.tcpv4v6 @-> Mimic.mimic @-> alpn_client)
