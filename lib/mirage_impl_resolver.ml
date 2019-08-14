open Functoria
module Key = Mirage_key
open Mirage_impl_misc
open Mirage_impl_time
open Mirage_impl_stackv4
open Mirage_impl_random
open Rresult

type resolver = Resolver
let resolver = Type Resolver

let resolver_unix_system = impl @@ object
    inherit base_configurable
    method ty = resolver
    method name = "resolver_unix"
    method module_name = "Resolver_lwt"
    method! packages =
      Key.(if_ is_unix)
        [ Mirage_impl_conduit_connector.pkg ;
          package ~min:"1.0.0" ~max:"2.0.0" "conduit-lwt-unix"; ]
        []
    method! configure i =
      match get_target i with
      | `Unix | `MacOSX -> R.ok ()
      | _ -> R.error_msg "Unix resolver not supported on non-UNIX targets."
    method! connect _ _modname _ = "Lwt.return Resolver_lwt_unix.system"
  end

let resolver_dns_conf ~ns ~ns_port = impl @@ object
    inherit base_configurable
    method ty = random @-> time @-> stackv4 @-> resolver
    method name = "resolver"
    method module_name = "Resolver_mirage.Make_with_stack"
    method! packages =
      Key.pure [ Mirage_impl_conduit_connector.pkg ]
    method! keys = [ Key.abstract ns ; Key.abstract ns_port ]
    method! connect _ modname = function
      | [ _r ; _t ; stack ] ->
        Fmt.strf
          "let ns = %a in@;\
           let ns_port = %a in@;\
           let res = %s.R.init ~ns ~ns_port ~stack:%s () in@;\
           Lwt.return res@;"
          pp_key ns pp_key ns_port modname stack
      | _ -> failwith (connect_err "resolver" 3)
  end

let resolver_dns ?ns ?ns_port ?(random = default_random) ?(time = default_time) stack =
  let ns = Key.resolver ?default:ns ()
  and ns_port = Key.resolver_port ?default:ns_port ()
  in
  resolver_dns_conf ~ns ~ns_port $ random $ time $ stack
