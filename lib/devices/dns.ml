open Functoria.DSL

type dns_client = Dns_client

let dns_client = typ Dns_client

let generic_dns_client ?dhcp ?group ?timeout ?nameservers ?cache_size () =
  Option.iter
    (fun (requests, _) -> Ip.Dhcp_requests.add requests 6 (* DNS_SERVERS *))
    dhcp;
  let packages = [ package "dns-client-mirage" ~min:"10.0.0" ~max:"11.0.0" ] in
  let nameservers = Runtime_arg.dns_servers ?group nameservers
  and timeout = Runtime_arg.dns_timeout ?group timeout
  and cache_size = Runtime_arg.dns_cache_size ?group cache_size in
  let runtime_args = Runtime_arg.[ v nameservers; v timeout; v cache_size ] in
  let packages, extra_deps, connect =
    match dhcp with
    | None ->
        let connect _info modname = function
          | [ stackv4v6; happy_eyeballs; nameservers; timeout; cache_size ] ->
              code ~pos:__POS__
                {ocaml|%s.connect @[?nameservers:%s ?timeout:%s ?cache_size:%s@ (%s, %s)@]|ocaml}
                modname nameservers timeout cache_size stackv4v6 happy_eyeballs
          | _ -> Misc.connect_err "generic_dns_client" 5
        in
        (packages, None, connect)
    | Some (_, lease) ->
        let connect _info modname = function
          | [
              stackv4v6; happy_eyeballs; lease; nameservers; timeout; cache_size;
            ] ->
              (* The nameservers argument has to be turned into a string. *)
              code ~pos:__POS__
                "let nameservers =@[@ match %s, %s with@ | None, None -> None@ \
                 | Some ns, _ -> Some ns@ | None, Some lease ->@[@ let \
                 nameservers = Dhcp_wire.collect_dns_servers lease in@.Some \
                 (List.concat_map (fun ip -> [Fmt.str \"udp:%%a\" Ipaddr.V4.pp \
                 ip; Fmt.str \"tcp:%%a\" Ipaddr.V4.pp ip]) \
                 nameservers)@]@]@.in@.%s.connect @[?nameservers ?timeout:%s \
                 ?cache_size:%s@ (%s, %s)@]"
                nameservers lease modname timeout cache_size stackv4v6
                happy_eyeballs
          | _ -> Misc.connect_err "generic_dns_client" 6
        in
        ( package ~min:"2.0.0" ~max:"3.0.0" "charrua" :: packages,
          Some [ dep lease ],
          connect )
  in
  impl ~runtime_args ~packages ?extra_deps ~connect "Dns_client_mirage.Make"
    (Stack.stackv4v6 @-> Happy_eyeballs.happy_eyeballs @-> dns_client)
