open Functoria.DSL
open Stack
open Misc

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

let tls =
  let packages = [ pkg; package ~min:"1.0.0" ~max:"2.0.0" "tls-mirage" ] in
  let connect _ _ = function
    | [ stack ] -> code ~pos:__POS__ "Lwt.return %s@;" stack
    | _ -> connect_err "tls_conduit" 1
  in
  impl ~packages ~connect "Conduit_mirage.TLS" (conduit @-> conduit)

let conduit_direct ?tls:(use_tls = false) s =
  if use_tls then tls $ (tcp $ s) else tcp $ s
