open Functoria
module Key = Mirage_key
open Mirage_impl_misc
open Mirage_impl_mclock
open Mirage_impl_stackv4
open Mirage_impl_random
open Mirage_impl_time

type resolver = Resolver
let resolver = Type Resolver

let resolver_dns_conf ~ns ~ns_port = impl @@ object
    inherit base_configurable
    method ty = random @-> time @-> mclock @-> stackv4 @-> resolver
    method name = "resolver"
    method module_name = "Conduit_mirage_dns.Make"
    method! packages =
      Key.pure [ Mirage_impl_conduit.pkg ["dns"] ]
    method! keys = [ Key.abstract ns ; Key.abstract ns_port ]
    method! connect _ modname = function
      | [ _r ; _t ; _m ; stack ] ->
        Fmt.strf
          "let ns = %a in@;\
           let ns_port = %a in@;\
           let res = %s.create ~nameserver:(`TCP, (ns, ns_port)) %s in@;\
           Lwt.return res@;"
          pp_key ns pp_key ns_port modname stack
      | _ -> failwith (connect_err "resolver" 3)
  end

let resolver_dns ?ns ?ns_port ?(random = default_random) ?(time = default_time) ?(mclock = default_monotonic_clock) stack =
  let ns = Key.resolver ?default:ns ()
  and ns_port = Key.resolver_port ?default:ns_port ()
  in
  resolver_dns_conf ~ns ~ns_port $ random $ time $ mclock $ stack
