open Functoria.DSL
open Functoria.Action

type resolver = Resolver

let resolver = typ Resolver

let resolver_unix_system =
  let packages_v =
    Key.(if_ is_unix)
      [ Conduit.pkg; package ~min:"8.0.0" ~max:"9.0.0" "conduit-lwt-unix" ]
      []
  in
  let configure i =
    match Misc.get_target i with
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
    | [ stack; ns ] ->
        code ~pos:__POS__
          "let nameservers = %s in@;\
           %s.v ?nameservers %s >|= function@;\
           | Ok r -> r@;\
           | Error (`Msg e) -> invalid_arg e@;"
          ns modname stack
    | _ -> Misc.connect_err "resolver" 2
  in
  impl ~packages ~runtime_args ~connect "Resolver_mirage.Make"
    (Stack.stackv4v6 @-> resolver)

let resolver_dns ?ns stack =
  let ns = Runtime_arg.resolver ?default:ns () in
  resolver_dns_conf ~ns $ stack
