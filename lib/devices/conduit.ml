open Functoria.DSL
open Stack
open Misc
open Random

type conduit = Conduit

let conduit = typ Conduit
let pkg = package ~min:"7.0.0" ~max:"8.0.0" "conduit-mirage"

let tcp =
  let packages = [ pkg ] in
  let connect _ _ = function
    | [ stack ] -> code ~pos:__POS__ "Lwt.return %s@;" stack
    | _ -> connect_err "tcp_conduit" 1
  in
  impl ~packages ~connect "Conduit_mirage.TCP" (stackv4v6 @-> conduit)

let tls random =
  let packages = [ pkg; package ~min:"1.0.0" ~max:"2.0.0" "tls-mirage" ] in
  let extra_deps = [ dep random ] in
  let connect _ _ = function
    | [ stack; _random ] -> code ~pos:__POS__ "Lwt.return %s@;" stack
    | _ -> connect_err "tls_conduit" 2
  in
  impl ~packages ~connect ~extra_deps "Conduit_mirage.TLS" (conduit @-> conduit)

let conduit_direct ?tls:(use_tls = false) ?(random = default_random) s =
  if use_tls then tls random $ (tcp $ s) else tcp $ s
