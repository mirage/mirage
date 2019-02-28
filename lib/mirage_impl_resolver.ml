open Functoria
module Key = Mirage_key
open Mirage_impl_misc
open Mirage_impl_time
open Mirage_impl_stackv4
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
    method! connect _ _modname _ = `Val "Resolver_lwt_unix.system"
  end

let meta_ipv4 ppf s =
  Fmt.pf ppf "(Ipaddr.V4.of_string_exn %S)" (Ipaddr.V4.to_string s)

let resolver_dns_conf ~ns ~ns_port = impl @@ object
    inherit base_configurable
    method ty = time @-> stackv4 @-> resolver
    method name = "resolver"
    method module_name = "Resolver_mirage.Make_with_stack"
    method! packages =
      Key.pure [ Mirage_impl_conduit_connector.pkg ]
    method! connect _ modname = function
      | [ _t ; stack ] ->
        let meta_ns = Fmt.Dump.option meta_ipv4 in
        let meta_port = Fmt.(Dump.option int) in
        `Eff
          (Fmt.strf
             "let ns = %a in@;\
              let ns_port = %a in@;\
              let res = %s.R.init ?ns ?ns_port ~stack:%s () in@;\
              Lwt.return res@;"
             meta_ns ns meta_port ns_port modname stack)
      | _ -> failwith (connect_err "resolver" 2)
  end

let resolver_dns ?ns ?ns_port ?(time = default_time) stack =
  resolver_dns_conf ~ns ~ns_port $ time $ stack
