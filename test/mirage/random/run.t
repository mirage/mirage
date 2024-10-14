Configure the project for Unix:

  $ mirage configure -t unix
  mirage: [WARNING] Skipping version check, since our_version is not watermarked
  $ ls . mirage/
  .:
  Makefile
  _build
  config.ml
  dist
  dune
  dune-project
  dune-workspace
  dune.build
  dune.config
  mirage
  
  mirage/:
  context
  dune-workspace.config
  main.ml
  random-unix.opam
  $ cat mirage/main.ml
  open Lwt.Infix
  type 'a io = 'a Lwt.t
  let return = Lwt.return
  Printexc.record_backtrace true
  let run t = Unix_os.Main.run t ; exit
  0
  
  let mirage_runtime_delay__key = Mirage_runtime.register_arg @@
  # 33 "lib/devices/runtime_arg.ml"
    Mirage_runtime.delay
  ;;
  
  let mirage_runtime_logs__key = Mirage_runtime.register_arg @@
  # 196 "lib/devices/runtime_arg.ml"
    Mirage_runtime.logs
  ;;
  
  let cmdliner_stdlib_setup_backtracesome_true_randomize_hashtablessome_true___key = Mirage_runtime.register_arg @@
  # 412 "lib/mirage.ml"
    Cmdliner_stdlib.setup ~backtrace:(Some true) ~randomize_hashtables:(Some true) ()
  ;;
  
  # 24 "mirage/main.ml"
  
  module Mirage_logs_make__6 = Mirage_logs.Make(Pclock)
  
  # 28 "mirage/main.ml"
  
  module Mirage_crypto_rng_mirage_make__9 = Mirage_crypto_rng_mirage.Make(Unix_os.Time)(Mclock)
  
  # 32 "mirage/main.ml"
  
  module App_make__10 = App.Make(Mirage_crypto_rng_mirage_make__9)
  
  let mirage_bootvar__1 = lazy (
  # 15 "lib/devices/argv.ml"
    return (Mirage_bootvar.argv ())
  );;
  # 40 "mirage/main.ml"
  
  let struct_end__2 = lazy (
    let __mirage_bootvar__1 = Lazy.force mirage_bootvar__1 in
    __mirage_bootvar__1 >>= fun _mirage_bootvar__1 ->
  # 47 "lib/functoria/job.ml"
    return Mirage_runtime.(with_argv (runtime_args ()) "random" _mirage_bootvar__1)
  );;
  # 48 "mirage/main.ml"
  
  let cmdliner_stdlib__3 = lazy (
    let _cmdliner_stdlib_setup_backtracesome_true_randomize_hashtablessome_true_ = (cmdliner_stdlib_setup_backtracesome_true_randomize_hashtablessome_true___key ()) in
    return (_cmdliner_stdlib_setup_backtracesome_true_randomize_hashtablessome_true_)
  );;
  # 54 "mirage/main.ml"
  
  let mirage_runtime__4 = lazy (
    let _mirage_runtime_delay = (mirage_runtime_delay__key ()) in
  # 309 "lib/mirage.ml"
    Unix_os.Time.sleep_ns (Duration.of_sec _mirage_runtime_delay)
  );;
  # 61 "mirage/main.ml"
  
  let pclock__5 = lazy (
    return ()
  );;
  # 66 "mirage/main.ml"
  
  let mirage_logs_make__6 = lazy (
    let __pclock__5 = Lazy.force pclock__5 in
    __pclock__5 >>= fun _pclock__5 ->
    let _mirage_runtime_logs = (mirage_runtime_logs__key ()) in
  # 22 "lib/devices/reporter.ml"
    let reporter = Mirage_logs_make__6.create () in
    Mirage_runtime.set_level ~default:(Some Logs.Info) _mirage_runtime_logs;
    Logs.set_reporter reporter;
    Lwt.return reporter
  );;
  # 78 "mirage/main.ml"
  
  let unix_os_time__7 = lazy (
    return ()
  );;
  # 83 "mirage/main.ml"
  
  let mclock__8 = lazy (
    return ()
  );;
  # 88 "mirage/main.ml"
  
  let mirage_crypto_rng_mirage_make__9 = lazy (
    let __unix_os_time__7 = Lazy.force unix_os_time__7 in
    let __mclock__8 = Lazy.force mclock__8 in
    __unix_os_time__7 >>= fun _unix_os_time__7 ->
    __mclock__8 >>= fun _mclock__8 ->
  # 15 "lib/devices/random.ml"
    Mirage_crypto_rng_mirage_make__9.initialize (module Mirage_crypto_rng.Fortuna)
  );;
  # 98 "mirage/main.ml"
  
  let app_make__10 = lazy (
    let __mirage_crypto_rng_mirage_make__9 = Lazy.force mirage_crypto_rng_mirage_make__9 in
    __mirage_crypto_rng_mirage_make__9 >>= fun _mirage_crypto_rng_mirage_make__9 ->
  # 3 "config.ml"
    (App_make__10.start _mirage_crypto_rng_mirage_make__9 : unit io)
  );;
  # 106 "mirage/main.ml"
  
  let mirage_runtime__11 = lazy (
    let __struct_end__2 = Lazy.force struct_end__2 in
    let __cmdliner_stdlib__3 = Lazy.force cmdliner_stdlib__3 in
    let __mirage_runtime__4 = Lazy.force mirage_runtime__4 in
    let __mirage_logs_make__6 = Lazy.force mirage_logs_make__6 in
    let __app_make__10 = Lazy.force app_make__10 in
    __struct_end__2 >>= fun _struct_end__2 ->
    __cmdliner_stdlib__3 >>= fun _cmdliner_stdlib__3 ->
    __mirage_runtime__4 >>= fun _mirage_runtime__4 ->
    __mirage_logs_make__6 >>= fun _mirage_logs_make__6 ->
    __app_make__10 >>= fun _app_make__10 ->
  # 393 "lib/mirage.ml"
    return ()
  );;
  # 122 "mirage/main.ml"
  
  let () =
    let t = Lazy.force struct_end__2 >>= fun _ ->
    Lazy.force cmdliner_stdlib__3 >>= fun _ ->
    Lazy.force mirage_runtime__4 >>= fun _ ->
    Lazy.force mirage_logs_make__6 >>= fun _ ->
    Lazy.force mirage_runtime__11 in
    run t
  ;;

  $ mirage clean


Configure the project for Xen:

  $ mirage configure -t xen
  mirage: [WARNING] Skipping version check, since our_version is not watermarked
  $ ls . mirage/
  .:
  Makefile
  _build
  config.ml
  dist
  dune
  dune-project
  dune-workspace
  dune.build
  dune.config
  mirage
  
  mirage/:
  context
  dune-workspace.config
  main.ml
  manifest.json
  manifest.ml
  random-xen.opam
  random.xl
  random.xl.in
  random_libvirt.xml
  $ cat mirage/main.ml
  open Lwt.Infix
  type 'a io = 'a Lwt.t
  let return = Lwt.return
  Printexc.record_backtrace true
  let run t = Xen_os.Main.run t ; exit
  0
  
  let mirage_runtime_delay__key = Mirage_runtime.register_arg @@
  # 33 "lib/devices/runtime_arg.ml"
    Mirage_runtime.delay
  ;;
  
  let mirage_runtime_logs__key = Mirage_runtime.register_arg @@
  # 196 "lib/devices/runtime_arg.ml"
    Mirage_runtime.logs
  ;;
  
  let cmdliner_stdlib_setup_backtracesome_true_randomize_hashtablessome_true___key = Mirage_runtime.register_arg @@
  # 412 "lib/mirage.ml"
    Cmdliner_stdlib.setup ~backtrace:(Some true) ~randomize_hashtables:(Some true) ()
  ;;
  
  # 24 "mirage/main.ml"
  
  module Mirage_logs_make__6 = Mirage_logs.Make(Pclock)
  
  # 28 "mirage/main.ml"
  
  module Mirage_crypto_rng_mirage_make__9 = Mirage_crypto_rng_mirage.Make(Xen_os.Time)(Mclock)
  
  # 32 "mirage/main.ml"
  
  module App_make__10 = App.Make(Mirage_crypto_rng_mirage_make__9)
  
  let mirage_bootvar__1 = lazy (
  # 15 "lib/devices/argv.ml"
    return (Mirage_bootvar.argv ())
  );;
  # 40 "mirage/main.ml"
  
  let struct_end__2 = lazy (
    let __mirage_bootvar__1 = Lazy.force mirage_bootvar__1 in
    __mirage_bootvar__1 >>= fun _mirage_bootvar__1 ->
  # 47 "lib/functoria/job.ml"
    return Mirage_runtime.(with_argv (runtime_args ()) "random" _mirage_bootvar__1)
  );;
  # 48 "mirage/main.ml"
  
  let cmdliner_stdlib__3 = lazy (
    let _cmdliner_stdlib_setup_backtracesome_true_randomize_hashtablessome_true_ = (cmdliner_stdlib_setup_backtracesome_true_randomize_hashtablessome_true___key ()) in
    return (_cmdliner_stdlib_setup_backtracesome_true_randomize_hashtablessome_true_)
  );;
  # 54 "mirage/main.ml"
  
  let mirage_runtime__4 = lazy (
    let _mirage_runtime_delay = (mirage_runtime_delay__key ()) in
  # 309 "lib/mirage.ml"
    Xen_os.Time.sleep_ns (Duration.of_sec _mirage_runtime_delay)
  );;
  # 61 "mirage/main.ml"
  
  let pclock__5 = lazy (
    return ()
  );;
  # 66 "mirage/main.ml"
  
  let mirage_logs_make__6 = lazy (
    let __pclock__5 = Lazy.force pclock__5 in
    __pclock__5 >>= fun _pclock__5 ->
    let _mirage_runtime_logs = (mirage_runtime_logs__key ()) in
  # 22 "lib/devices/reporter.ml"
    let reporter = Mirage_logs_make__6.create () in
    Mirage_runtime.set_level ~default:(Some Logs.Info) _mirage_runtime_logs;
    Logs.set_reporter reporter;
    Lwt.return reporter
  );;
  # 78 "mirage/main.ml"
  
  let xen_os_time__7 = lazy (
    return ()
  );;
  # 83 "mirage/main.ml"
  
  let mclock__8 = lazy (
    return ()
  );;
  # 88 "mirage/main.ml"
  
  let mirage_crypto_rng_mirage_make__9 = lazy (
    let __xen_os_time__7 = Lazy.force xen_os_time__7 in
    let __mclock__8 = Lazy.force mclock__8 in
    __xen_os_time__7 >>= fun _xen_os_time__7 ->
    __mclock__8 >>= fun _mclock__8 ->
  # 15 "lib/devices/random.ml"
    Mirage_crypto_rng_mirage_make__9.initialize (module Mirage_crypto_rng.Fortuna)
  );;
  # 98 "mirage/main.ml"
  
  let app_make__10 = lazy (
    let __mirage_crypto_rng_mirage_make__9 = Lazy.force mirage_crypto_rng_mirage_make__9 in
    __mirage_crypto_rng_mirage_make__9 >>= fun _mirage_crypto_rng_mirage_make__9 ->
  # 3 "config.ml"
    (App_make__10.start _mirage_crypto_rng_mirage_make__9 : unit io)
  );;
  # 106 "mirage/main.ml"
  
  let mirage_runtime__11 = lazy (
    let __struct_end__2 = Lazy.force struct_end__2 in
    let __cmdliner_stdlib__3 = Lazy.force cmdliner_stdlib__3 in
    let __mirage_runtime__4 = Lazy.force mirage_runtime__4 in
    let __mirage_logs_make__6 = Lazy.force mirage_logs_make__6 in
    let __app_make__10 = Lazy.force app_make__10 in
    __struct_end__2 >>= fun _struct_end__2 ->
    __cmdliner_stdlib__3 >>= fun _cmdliner_stdlib__3 ->
    __mirage_runtime__4 >>= fun _mirage_runtime__4 ->
    __mirage_logs_make__6 >>= fun _mirage_logs_make__6 ->
    __app_make__10 >>= fun _app_make__10 ->
  # 393 "lib/mirage.ml"
    return ()
  );;
  # 122 "mirage/main.ml"
  
  let () =
    let t = Lazy.force struct_end__2 >>= fun _ ->
    Lazy.force cmdliner_stdlib__3 >>= fun _ ->
    Lazy.force mirage_runtime__4 >>= fun _ ->
    Lazy.force mirage_logs_make__6 >>= fun _ ->
    Lazy.force mirage_runtime__11 in
    run t
  ;;

  $ mirage clean
