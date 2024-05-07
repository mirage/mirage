open Functoria.DSL
open Functoria.Action
open Misc
open Mclock
open Pclock
open Stack
open Random
open Time

type resolver = Resolver

let resolver = typ Resolver

let resolver_unix_system =
  let packages_v =
    Key.(if_ is_unix)
      [ Conduit.pkg; package ~min:"7.0.0" ~max:"8.0.0" "conduit-lwt-unix" ]
      []
  in
  let configure i =
    match get_target i with
    | `Unix | `MacOSX -> ok ()
    | _ -> error "Unix resolver not supported on non-UNIX targets."
  in
  let connect _ _modname _ =
    code ~pos:__POS__ "Lwt.return Resolver_lwt_unix.system"
  in
  impl ~packages_v ~configure ~connect "Resolver_lwt" resolver

let resolver_dns_conf ~ns =
  let packages = [ Conduit.pkg ] in
  let runtime_args = Runtime_arg.[ v ns ] in
  let connect _ modname = function
    | [ _r; _m; _p; stack; _time; ns ] ->
        code ~pos:__POS__
          "let nameservers = %s in@;\
           %s.v ?nameservers %s >|= function@;\
           | Ok r -> r@;\
           | Error (`Msg e) -> invalid_arg e@;"
          ns modname stack
    | _ -> connect_err "resolver" 6
  in
  let extra_deps = [ dep default_time ] in
  impl ~extra_deps ~packages ~runtime_args ~connect "Resolver_mirage.Make"
    (random @-> mclock @-> pclock @-> stackv4v6 @-> resolver)

let resolver_dns ?ns ?(mclock = default_monotonic_clock)
    ?(pclock = default_posix_clock) ?(random = default_random) stack =
  let ns = Runtime_arg.resolver ?default:ns () in
  resolver_dns_conf ~ns $ random $ mclock $ pclock $ stack
