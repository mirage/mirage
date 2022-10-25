open Functoria
module Key = Mirage_key
open Mirage_impl_misc
open Mirage_impl_mclock
open Mirage_impl_pclock
open Mirage_impl_stack
open Mirage_impl_random
open Mirage_impl_time

type resolver = Resolver

let resolver = Type.v Resolver

let resolver_unix_system =
  let packages_v =
    Key.(if_ is_unix)
      [
        Mirage_impl_conduit.pkg;
        package ~min:"4.0.0" ~max:"7.0.0" "conduit-lwt-unix";
      ]
      []
  in
  let configure i =
    match get_target i with
    | `Unix | `MacOSX -> Action.ok ()
    | _ -> Action.error "Unix resolver not supported on non-UNIX targets."
  in
  let connect _ _modname _ = "Lwt.return Resolver_lwt_unix.system" in
  impl ~packages_v ~configure ~connect "Resolver_lwt" resolver

let resolver_dns_conf ~ns =
  let packages = [ Mirage_impl_conduit.pkg ] in
  let keys = Key.[ v ns ] in
  let connect _ modname = function
    | [ _r; _t; _m; _p; stack ] ->
        Fmt.str
          "let nameservers = %a in@;\
           %s.v ?nameservers %s >|= function@;\
           | Ok r -> r@;\
           | Error (`Msg e) -> invalid_arg e@;"
          pp_key ns modname stack
    | _ -> failwith (connect_err "resolver" 3)
  in
  impl ~packages ~keys ~connect "Resolver_mirage.Make"
    (random @-> time @-> mclock @-> pclock @-> stackv4v6 @-> resolver)

let resolver_dns ?ns ?(time = default_time) ?(mclock = default_monotonic_clock)
    ?(pclock = default_posix_clock) ?(random = default_random) stack =
  let ns = Key.resolver ?default:ns () in
  resolver_dns_conf ~ns $ random $ time $ mclock $ pclock $ stack
