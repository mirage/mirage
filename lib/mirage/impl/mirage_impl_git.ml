open Functoria
open Mirage_impl_time
open Mirage_impl_mclock
open Mirage_impl_pclock
open Mirage_impl_tcp
open Mirage_impl_mimic
open Mirage_impl_misc

type git_client = Git_client

let git_client = Type.v Git_client

let git_merge_clients =
  let packages = [ package "mimic" ] in
  let connect _ _modname = function
    | [ a; b ] -> Fmt.str "Lwt.return (Mimic.merge %s %s)" a b
    | [ x ] -> Fmt.str "%s.ctx" x
    | _ -> Fmt.str "Lwt.return Mimic.empty"
  in
  impl ~packages ~connect "Mimic.Merge"
    (git_client @-> git_client @-> git_client)

let git_tcp =
  let packages =
    [ package "git-mirage" ~sublibs:[ "tcp" ] ~min:"3.10.0" ~max:"3.16.0" ]
  in
  let connect _ modname = function
    | [ _tcpv4v6; ctx ] -> Fmt.str {ocaml|%s.connect %s|ocaml} modname ctx
    | _ -> connect_err "git_tcp" 2
  in
  impl ~packages ~connect "Git_mirage_tcp.Make"
    (tcpv4v6 @-> mimic @-> git_client)

let git_ssh ?authenticator key password =
  let packages =
    [ package "git-mirage" ~sublibs:[ "ssh" ] ~min:"3.13.0" ~max:"3.16.0" ]
  in
  let connect _ modname = function
    | [ _mclock; _tcpv4v6; _time; ctx ] ->
        Fmt.str {ocaml|%s.connect %s >>= %s.with_optionnal_key%a%a%a|ocaml}
          modname ctx modname (pp_opt "authenticator") authenticator
          (pp_label "key") (Some key) (pp_label "password") (Some password)
    | _ -> connect_err "git_sssh" 4
  in
  let runtime_args =
    runtime_args_opt [ Some key; Some password; authenticator ]
  in
  impl ~packages ~connect ~runtime_args "Git_mirage_ssh.Make"
    (mclock @-> tcpv4v6 @-> time @-> mimic @-> git_client)

let git_http ?authenticator headers =
  let packages =
    [ package "git-mirage" ~sublibs:[ "http" ] ~min:"3.10.0" ~max:"3.16.0" ]
  in
  let runtime_args = runtime_args_opt [ headers; authenticator ] in
  let connect _ modname = function
    | [ _pclock; _tcpv4v6; ctx ] ->
        Fmt.str
          {ocaml|%s.connect %s >>= fun ctx ->
           %s.with_optional_tls_config_and_headers%a%a ctx|ocaml}
          modname ctx modname (pp_opt "authenticator") authenticator
          (pp_opt "headers") headers
    | _ -> connect_err "git_http" 3
  in
  impl ~packages ~connect ~runtime_args "Git_mirage_http.Make"
    (pclock @-> tcpv4v6 @-> mimic @-> git_client)
