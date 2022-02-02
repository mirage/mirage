open Functoria
open Mirage_impl_time
open Mirage_impl_mclock
open Mirage_impl_pclock
open Mirage_impl_stack
open Mirage_impl_tcp
open Mirage_impl_dns
open Mirage_impl_happy_eyeballs

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

let git_happy_eyeballs =
  let packages = [ package "mimic-happy-eyeballs" ~min:"0.0.5" ] in
  let connect _ modname = function
    | [ _stackv4v6; _dns_client; happy_eyeballs ] ->
        Fmt.str {ocaml|%s.connect %s|ocaml} modname happy_eyeballs
    | _ -> assert false
  in
  impl ~packages ~connect "Mimic_happy_eyeballs.Make"
    (stackv4v6 @-> dns_client @-> happy_eyeballs @-> git_client)

let git_tcp =
  let packages =
    [ package "git-mirage" ~sublibs:[ "tcp" ] ~min:"3.9.0" ~max:"3.10.0" ]
  in
  let connect _ modname = function
    | [ _tcpv4v6; ctx ] -> Fmt.str {ocaml|%s.connect %s|ocaml} modname ctx
    | _ -> assert false
  in
  impl ~packages ~connect "Git_mirage_tcp.Make"
    (tcpv4v6 @-> git_client @-> git_client)

let git_ssh ?authenticator key =
  let packages =
    [ package "git-mirage" ~sublibs:[ "ssh" ] ~min:"3.9.0" ~max:"3.10.0" ]
  in
  let connect _ modname = function
    | [ _mclock; _tcpv4v6; _time; ctx ] -> (
        match authenticator with
        | None ->
            Fmt.str
              {ocaml|%s.connect %s >>= %s.with_optionnal_key ~key:%a|ocaml}
              modname ctx modname Key.serialize_call (Key.v key)
        | Some authenticator ->
            Fmt.str
              {ocaml|%s.connect %s >>= %s.with_optionnal_key ?authenticator:%a ~key:%a|ocaml}
              modname ctx modname Key.serialize_call (Key.v authenticator)
              Key.serialize_call (Key.v key))
    | _ -> assert false
  in
  let keys =
    match authenticator with
    | Some authenticator -> [ Key.v key; Key.v authenticator ]
    | None -> [ Key.v key ]
  in
  impl ~packages ~connect ~keys "Git_mirage_ssh.Make"
    (mclock @-> tcpv4v6 @-> time @-> git_client @-> git_client)

let git_http ?authenticator headers =
  let packages =
    [ package "git-mirage" ~sublibs:[ "http" ] ~min:"3.9.0" ~max:"3.10.0" ]
  in
  let keys =
    let keys = [] in
    let keys =
      match headers with Some headers -> Key.v headers :: keys | None -> keys
    in
    let keys =
      match authenticator with
      | Some authenticator -> Key.v authenticator :: keys
      | None -> []
    in
    keys
  in
  let connect _ modname = function
    | [ _time; _pclock; _tcpv4v6; ctx ] ->
        let serialize_headers ppf = function
          | None -> ()
          | Some headers ->
              Fmt.pf ppf " ?headers:%a" Key.serialize_call (Key.v headers)
        in
        let serialize_authenticator ppf = function
          | None -> ()
          | Some authenticator ->
              Fmt.pf ppf " ?authenticator:%a" Key.serialize_call
                (Key.v authenticator)
        in
        Fmt.str
          {ocaml|%s.connect %s >>= fun ctx -> %s.with_optional_tls_config_and_headers%a%a ctx|ocaml}
          modname ctx modname serialize_authenticator authenticator
          serialize_headers headers
    | _ -> assert false
  in
  impl ~packages ~connect ~keys "Git_mirage_http.Make"
    (time @-> pclock @-> tcpv4v6 @-> git_client @-> git_client)
