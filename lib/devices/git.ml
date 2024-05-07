open Functoria.DSL
open Time
open Mclock
open Pclock
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
    [ package "git-mirage" ~sublibs:[ "tcp" ] ~min:"3.10.0" ~max:"3.18.0" ]
  in
  let connect _ modname = function
    | [ _tcpv4v6; ctx ] ->
        code ~pos:__POS__ {ocaml|%s.connect %s|ocaml} modname ctx
    | _ -> connect_err "git_tcp" 2
  in
  impl ~packages ~connect "Git_mirage_tcp.Make"
    (tcpv4v6 @-> mimic @-> git_client)

let git_ssh ?authenticator key password =
  let packages =
    [ package "git-mirage" ~sublibs:[ "ssh" ] ~min:"3.13.0" ~max:"3.18.0" ]
  in
  let err () = connect_err "git_ssh" 4 ~max:7 in
  let connect _ modname = function
    | _mclock :: _tcpv4v6 :: ctx :: _time :: rest ->
        let key, rest = pop ~err (Some key) rest in
        let password, rest = pop ~err (Some password) rest in
        let authenticator = pop_and_check_empty ~err authenticator rest in
        code ~pos:__POS__
          {ocaml|%s.connect %s >>= %s.with_optionnal_key %a %a %a|ocaml} modname
          ctx modname (pp_opt "authenticator") authenticator (pp_label "key")
          key (pp_label "password") password
    | _ -> err ()
  in
  let runtime_args =
    runtime_args_opt [ Some key; Some password; authenticator ]
  in
  let extra_deps = [ dep default_time ] in
  impl ~extra_deps ~packages ~connect ~runtime_args "Git_mirage_ssh.Make"
    (mclock @-> tcpv4v6 @-> mimic @-> git_client)

let git_http ?authenticator headers =
  let packages =
    [ package "git-mirage" ~sublibs:[ "http" ] ~min:"3.10.0" ~max:"3.18.0" ]
  in
  let runtime_args = runtime_args_opt [ headers; authenticator ] in
  let err () = connect_err "git_http" 3 ~max:5 in
  let connect _ modname = function
    | _pclock :: _tcpv4v6 :: ctx :: rest ->
        let headers, rest = pop ~err headers rest in
        let authenticator = pop_and_check_empty ~err authenticator rest in
        code ~pos:__POS__
          {ocaml|%s.connect %s >>= fun ctx -> %s.with_optional_tls_config_and_headers%a%a ctx|ocaml}
          modname ctx modname (pp_opt "authenticator") authenticator
          (pp_opt "headers") headers
    | _ -> err ()
  in
  impl ~packages ~connect ~runtime_args "Git_mirage_http.Make"
    (pclock @-> tcpv4v6 @-> mimic @-> git_client)
