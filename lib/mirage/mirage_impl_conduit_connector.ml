open Functoria
open Mirage_impl_misc
open Mirage_impl_stackv4

type conduit_connector = Conduit_connector

let conduit_connector = Type.v Conduit_connector

let pkg = package ~min:"2.0.2" ~max:"3.0.0" "conduit-mirage"

let tcp_conduit_connector =
  let packages = [ pkg ] in
  let connect _ modname = function
    | [ stack ] -> Fmt.strf "Lwt.return (%s.connect %s)@;" modname stack
    | _ -> failwith (connect_err "tcp conduit" 1)
  in
  impl ~packages ~connect "Conduit_mirage.With_tcp"
    (stackv4 @-> conduit_connector)

let tls_conduit_connector =
  let packages = [ package ~min:"0.11.0" ~max:"0.12.0" "tls-mirage"; pkg ] in
  let connect _ _ _ = "Lwt.return Conduit_mirage.with_tls" in
  impl ~packages ~connect "Conduit_mirage" conduit_connector
