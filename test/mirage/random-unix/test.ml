open Mirage

let test () =
  let context = Key.add_to_context Key.target `Unix Key.empty_context in
  let sigs = conduit @-> random @-> job in
  let network = default_network in
  let etif = etif network in
  let arp = arp etif in
  let ipv4 = create_ipv4 etif arp in
  let ipv6 = create_ipv6 network etif in
  let stackv4v6 =
    direct_stackv4v6 ~ipv4_only:(Key.ipv4_only ()) ~ipv6_only:(Key.ipv6_only ())
      network etif arp ipv4 ipv6
  in
  let job =
    main "App.Make" sigs $ conduit_direct ~tls:true stackv4v6 $ default_random
  in
  Functoria_test.run context job

let () =
  match Functoria.Action.run (test ()) with
  | Ok () -> ()
  | Error (`Msg e) -> failwith e
