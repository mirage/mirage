open Functoria.DSL

type conduit = Conduit

let conduit = typ Conduit
let pkg = package ~min:"8.0.0" ~max:"9.0.0" "conduit-mirage"

let tcp =
  let packages = [ pkg ] in
  let connect _ _ = function
    | [ stack ] -> code ~pos:__POS__ "Lwt.return %s@;" stack
    | _ -> Misc.connect_err "tcp_conduit" 1
  in
  impl ~packages ~connect "Conduit_mirage.TCP" (Stack.stackv4v6 @-> conduit)

let tls =
  let packages = [ pkg; package ~min:"2.0.0" ~max:"3.0.0" "tls-mirage" ] in
  let connect _ _ = function
    | [ stack ] -> code ~pos:__POS__ "Lwt.return %s@;" stack
    | _ -> Misc.connect_err "tls_conduit" 1
  in
  impl ~packages ~connect "Conduit_mirage.TLS" (conduit @-> conduit)

let conduit_direct ?tls:(use_tls = false) s =
  if use_tls then tls $ (tcp $ s) else tcp $ s
