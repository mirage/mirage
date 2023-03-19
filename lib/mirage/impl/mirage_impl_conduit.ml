open Functoria
open Mirage_impl_stack
open Mirage_impl_misc
open Mirage_impl_random

type conduit = Conduit

let conduit = Type.v Conduit
let pkg = package ~min:"6.0.1" ~max:"7.0.0" "conduit-mirage"

let tcp =
  let packages = [ pkg ] in
  let connect _ _ = function
    | [ stack ] -> Fmt.str "Lwt.return %s@;" stack
    | _ -> failwith (connect_err "tcp_conduit" 1)
  in
  impl ~packages ~connect "Conduit_mirage.TCP" (stackv4v6 @-> conduit)

let tls random =
  let packages = [ pkg; package ~min:"0.13.0" ~max:"0.18.0" "tls-mirage" ] in
  let extra_deps = [ dep random ] in
  let connect _ _ = function
    | [ stack; _random ] -> Fmt.str "Lwt.return %s@;" stack
    | _ -> failwith (connect_err "tls_conduit" 1)
  in
  impl ~packages ~connect ~extra_deps "Conduit_mirage.TLS" (conduit @-> conduit)

let conduit_direct ?tls:(use_tls = false) ?(random = default_random) s =
  if use_tls then tls random $ (tcp $ s) else tcp $ s
