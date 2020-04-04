open Functoria
module Key = Mirage_key
open Mirage_impl_misc
open Mirage_impl_mclock
open Mirage_impl_stackv4
open Mirage_impl_random

type resolver = Resolver

let resolver = Type.v Resolver

let resolver_unix_system =
  let packages_v =
    Key.(if_ is_unix)
      [
        Mirage_impl_conduit_connector.pkg;
        package ~min:"2.0.2" ~max:"3.0.0" "conduit-lwt-unix";
      ]
      []
  in
  let build i =
    match get_target i with
    | `Unix | `MacOSX -> Action.ok ()
    | _ -> Action.error "Unix resolver not supported on non-UNIX targets."
  in
  let connect _ _modname _ = "Lwt.return Resolver_lwt_unix.system" in
  impl ~packages_v ~build ~connect "Resolver_lwt" resolver

let resolver_dns_conf ~ns ~ns_port =
  let packages = [ Mirage_impl_conduit_connector.pkg ] in
  let keys = Key.[ v ns; v ns_port ] in
  let connect _ modname = function
    | [ _r; _t; stack ] ->
        Fmt.strf
          "let ns = %a in@;\
           let ns_port = %a in@;\
           let res = %s.R.init ~ns ~ns_port ~stack:%s () in@;\
           Lwt.return res@;"
          pp_key ns pp_key ns_port modname stack
    | _ -> failwith (connect_err "resolver" 3)
  in
  impl ~packages ~keys ~connect "Resolver_mirage.Make_with_stack"
    (random @-> mclock @-> stackv4 @-> resolver)

let resolver_dns ?ns ?ns_port ?(random = default_random)
    ?(mclock = default_monotonic_clock) stack =
  let ns = Key.resolver ?default:ns ()
  and ns_port = Key.resolver_port ?default:ns_port () in
  resolver_dns_conf ~ns ~ns_port $ random $ mclock $ stack
