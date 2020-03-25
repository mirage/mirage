open Mirage

let test () =
  let context = Key.add_to_context Key.target `Unix Key.empty_context in
  let sigs = conduit @-> random @-> job in
  let network = default_network in
  let etif = etif network in
  let arp = arp etif in
  let ipv4 = create_ipv4 etif arp in
  let stackv4 = direct_stackv4 network etif arp ipv4 in
  let job =
    main "App.Make" sigs $ conduit_direct ~tls:true stackv4 $ default_random
  in
  Functoria_test.run context job

let () =
  match Functoria.Action.run (test ()) with
  | Ok () -> ()
  | Error (`Msg e) -> failwith e
