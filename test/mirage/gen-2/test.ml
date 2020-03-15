module Init = struct
  open Functoria
  open Action.Infix

  (* yiikes *)
  let () =
    Codegen.set_main_ml "main.ml";
    Codegen.append_main "let (>>=) x f = f x";
    Codegen.append_main "let return x = x";
    Codegen.append_main "let run x = x";
    Codegen.newline_main ()

  let target = Key.abstract Mirage.Key.target

  let test_device context device =
    let t = Graph.create device in
    let t = Graph.eval ~context t in
    let keys = target :: Key.Set.elements (Engine.all_keys t) in
    let packages = Key.eval context (Engine.packages t) in
    let info =
      Functoria.Info.v ~packages ~context ~keys
        ~build_dir:Fpath.(v ".")
        ~build_cmd:[ "build"; "me" ] ~src:`None "foo"
    in
    Engine.configure info t >>= fun () ->
    Engine.connect info t;
    Engine.build info t
end

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
  Init.test_device context job

let () =
  match Functoria.Action.run (test ()) with
  | Ok () -> ()
  | Error (`Msg e) -> failwith e
