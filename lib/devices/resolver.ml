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

let resolver_dns_conf ~dhcp ~ns =
  Option.iter
    (fun (requests, _) -> Ip.Dhcp_requests.add requests 6 (* DNS_SERVERS *))
    dhcp;
  let packages = [ Conduit.pkg ] in
  let runtime_args = Runtime_arg.[ v ns ] in
  let packages, extra_deps, connect =
    match dhcp with
    | None ->
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
        (packages, None, connect)
    | Some (_, lease) ->
        let connect _ modname = function
          | [ stack; lease; ns ] ->
              code ~pos:__POS__
                "let nameservers =@[@ match %s, %s with@ | None, None -> None@ \
                 | Some ns, _ -> Some ns@ | None, Some lease ->@[@ let \
                 nameservers = Dhcp_wire.collect_dns_servers lease in@.Some \
                 (List.concat_map (fun ip -> [Fmt.str \"udp:%%a\" Ipaddr.V4.pp \
                 ip; Fmt.str \"tcp:%%a\" Ipaddr.V4.pp ip]) nameservers)@]@]@.in\n\
                \             %s.v ?nameservers %s >|= function@;\
                 | Ok r -> r@;\
                 | Error (`Msg e) -> invalid_arg e@;"
                ns lease modname stack
          | _ -> Misc.connect_err "resolver" 3
        in
        let packages =
          package ~min:"2.0.0" ~max:"3.0.0" "charrua" :: packages
        in
        (packages, Some [ dep lease ], connect)
  in
  impl ~packages ?extra_deps ~runtime_args ~connect "Resolver_mirage.Make"
    (Stack.stackv4v6 @-> resolver)

let resolver_dns ?dhcp ?ns stack =
  let ns = Runtime_arg.resolver ?default:ns () in
  resolver_dns_conf ~dhcp ~ns $ stack
