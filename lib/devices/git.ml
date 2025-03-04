open Functoria.DSL
open Tcp
open Mimic
open Misc

type git_client = Git_client

let git_client = typ Git_client

let git_merge_clients =
  let packages = [ package "mimic" ] in
  let connect _ _modname = function
    | [ a; b ] -> code ~pos:__POS__ "Lwt.return (Mimic.merge %s %s)" a b
    | _ -> connect_err "git_merge_client" 2
  in
  impl ~packages ~connect "Mimic.Merge"
    (git_client @-> git_client @-> git_client)

let git_tcp =
  let packages =
    [ package "git-mirage" ~sublibs:[ "tcp" ] ~min:"3.18.0" ~max:"3.19.0" ]
  in
  let connect _ modname = function
    | [ _tcpv4v6; ctx ] ->
        code ~pos:__POS__ {ocaml|%s.connect %s|ocaml} modname ctx
    | _ -> connect_err "git_tcp" 2
  in
  impl ~packages ~connect "Git_mirage_tcp.Make"
    (tcpv4v6 @-> mimic @-> git_client)

let git_ssh ?group ?authenticator ?key ?password () =
  let packages =
    [ package "git-mirage" ~sublibs:[ "ssh" ] ~min:"3.18.0" ~max:"3.19.0" ]
  in
  let key = Runtime_arg.ssh_key ?group key
  and password = Runtime_arg.ssh_password ?group password
  and authenticator = Runtime_arg.ssh_authenticator ?group authenticator in
  let runtime_args = Runtime_arg.[ v key; v password; v authenticator ] in
  let connect _ modname = function
    | [ _tcpv4v6; ctx; key; password; authenticator ] ->
        code ~pos:__POS__
          {ocaml|%s.connect %s >>= %s.with_optionnal_key ?authenticator:%s ~key:%s ~password:%s|ocaml}
          modname ctx modname authenticator key password
    | _ -> connect_err "git_ssh" 5
  in
  impl ~packages ~connect ~runtime_args "Git_mirage_ssh.Make"
    (tcpv4v6 @-> mimic @-> git_client)

let git_http ?group ?authenticator ?headers () =
  let packages =
    [ package "git-mirage" ~sublibs:[ "http" ] ~min:"3.18.0" ~max:"3.19.0" ]
  in
  let authenticator = Runtime_arg.tls_authenticator ?group authenticator
  and headers = Runtime_arg.http_headers ?group headers in
  let runtime_args = Runtime_arg.[ v authenticator; v headers ] in
  let connect _ modname = function
    | [ _tcpv4v6; ctx; authenticator; headers ] ->
        code ~pos:__POS__
          {ocaml|%s.connect %s >>= %s.with_optional_tls_config_and_headers ?headers:%s ?authenticator:%s|ocaml}
          modname ctx modname headers authenticator
    | _ -> connect_err "git_http" 4
  in
  impl ~packages ~connect ~runtime_args "Git_mirage_http.Make"
    (tcpv4v6 @-> mimic @-> git_client)
