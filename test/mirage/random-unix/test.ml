open Mirage

let opt =
  let doc = Key.Arg.info ~doc:"An optional key." [ "opt" ] in
  Key.(create "opt" Arg.(opt ~stage:`Run string "default" doc))

let opt_all =
  let doc = Key.Arg.info ~doc:"All the optional keys." [ "opt-all" ] in
  Key.(create "opt-all" Arg.(opt_all ~stage:`Run string doc))

let flag =
  let doc = Key.Arg.info ~doc:"A flag." [ "flag" ] in
  Key.(create "flag" Arg.(flag ~stage:`Run doc))

let required =
  let doc = Key.Arg.info ~doc:"A required key." [ "required" ] in
  Key.(create "required" Arg.(required ~stage:`Run string doc))

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
  let init = Functoria.(keys sys_argv) in
  let job =
    main "App.Make" sigs $ conduit_direct ~tls:true stackv4v6 $ default_random
  in

  let job =
    let connect _ _ _ = "return ()" in
    Functoria.impl
      ~keys:Key.[ v opt; v opt_all; v flag; v required ]
      ~extra_deps:[ dep job; dep init ]
      "Functoria_runtime" ~connect Functoria.job
  in
  Functoria_test.run context job

let () =
  match Functoria.Action.run (test ()) with
  | Ok () -> ()
  | Error (`Msg e) -> failwith e
