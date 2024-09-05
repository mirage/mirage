open Functoria.DSL
open Pclock
open Misc
open Conduit
open Resolver
open Tcp
open Mimic

type http = HTTP

let http = typ HTTP

type http_client = HTTP_client

let http_client = typ HTTP_client

let connect err _i modname = function
  | [ conduit ] -> code ~pos:__POS__ "Lwt.return (%s.listen %s)" modname conduit
  | _ -> connect_err err 1

let cohttp_server =
  let packages = [ package ~min:"4.0.0" ~max:"6.0.0" "cohttp-mirage" ] in
  impl ~packages ~connect:(connect "http") "Cohttp_mirage.Server.Make"
    (conduit @-> http)

let cohttp_server conduit = cohttp_server $ conduit

let cohttp_client =
  let packages = [ package ~min:"4.0.0" ~max:"6.0.0" "cohttp-mirage" ] in
  let connect _i modname = function
    | [ _pclock; resolver; conduit ] ->
        code ~pos:__POS__ "Lwt.return (%s.ctx %s %s)" modname resolver conduit
    | _ -> connect_err "http" 3
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

let http_server = typ HTTP_server

let paf_server port =
  let connect _ modname = function
    | [ tcpv4v6; port ] ->
        code ~pos:__POS__ {ocaml|%s.init ~port:%s %s|ocaml} modname port tcpv4v6
    | _ -> connect_err "paf_server" 2
  in
  let packages =
    [ package "paf" ~sublibs:[ "mirage" ] ~min:"0.7.0" ~max:"0.8.0" ]
  in
  let runtime_args = Runtime_arg.[ v port ] in
  impl ~connect ~packages ~runtime_args "Paf_mirage.Make"
    (tcpv4v6 @-> http_server)

type alpn_client = ALPN_client

let alpn_client = typ ALPN_client

let paf_client =
  let packages = [ package "http-mirage-client" ~min:"0.0.1" ~max:"0.1.0" ] in
  let connect _ modname = function
    | [ _pclock; _tcpv4v6; ctx ] ->
        code ~pos:__POS__ {ocaml|%s.connect %s|ocaml} modname ctx
    | _ -> connect_err "paf_client" 3
  in
  impl ~connect ~packages "Http_mirage_client.Make"
    (pclock @-> tcpv4v6 @-> mimic @-> alpn_client)
