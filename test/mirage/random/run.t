Configure the project for Unix:

  $ mirage configure -t unix
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
  let run t = Unix_os.Main.run t ; exit
  0
  
  let mirage_runtime_delay__key = Mirage_runtime.register @@
  # 33 "lib/devices/runtime_arg.ml"
    Mirage_runtime.delay
  ;;
  
  let mirage_runtime_backtrace__key = Mirage_runtime.register @@
  # 34 "lib/devices/runtime_arg.ml"
    Mirage_runtime.backtrace
  ;;
  
  let mirage_runtime_randomize_hashtables__key = Mirage_runtime.register @@
  # 35 "lib/devices/runtime_arg.ml"
    Mirage_runtime.randomize_hashtables
  ;;
  
  let mirage_runtime_allocation_policy__key = Mirage_runtime.register @@
  # 36 "lib/devices/runtime_arg.ml"
    Mirage_runtime.allocation_policy
  ;;
  
  let mirage_runtime_minor_heap_size__key = Mirage_runtime.register @@
  # 37 "lib/devices/runtime_arg.ml"
    Mirage_runtime.minor_heap_size
  ;;
  
  let mirage_runtime_major_heap_increment__key = Mirage_runtime.register @@
  # 38 "lib/devices/runtime_arg.ml"
    Mirage_runtime.major_heap_increment
  ;;
  
  let mirage_runtime_space_overhead__key = Mirage_runtime.register @@
  # 39 "lib/devices/runtime_arg.ml"
    Mirage_runtime.space_overhead
  ;;
  
  let mirage_runtime_max_space_overhead__key = Mirage_runtime.register @@
  # 40 "lib/devices/runtime_arg.ml"
    Mirage_runtime.max_space_overhead
  ;;
  
  let mirage_runtime_gc_verbosity__key = Mirage_runtime.register @@
  # 41 "lib/devices/runtime_arg.ml"
    Mirage_runtime.gc_verbosity
  ;;
  
  let mirage_runtime_gc_window_size__key = Mirage_runtime.register @@
  # 42 "lib/devices/runtime_arg.ml"
    Mirage_runtime.gc_window_size
  ;;
  
  let mirage_runtime_custom_major_ratio__key = Mirage_runtime.register @@
  # 43 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_major_ratio
  ;;
  
  let mirage_runtime_custom_minor_ratio__key = Mirage_runtime.register @@
  # 44 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_minor_ratio
  ;;
  
  let mirage_runtime_custom_minor_max_size__key = Mirage_runtime.register @@
  # 45 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_minor_max_size
  ;;
  
  let mirage_runtime_logs__key = Mirage_runtime.register @@
  # 143 "lib/devices/runtime_arg.ml"
    Mirage_runtime.logs
  ;;
  
  # 78 "mirage/main.ml"
  
  module Mirage_logs_make__9 = Mirage_logs.Make(Pclock)
  
  # 82 "mirage/main.ml"
  
  module Mirage_crypto_rng_mirage_make__11 = Mirage_crypto_rng_mirage.Make(Mclock)
  
  # 86 "mirage/main.ml"
  
  module App_make__12 = App.Make(Mirage_crypto_rng_mirage_make__11)
  
  let mirage_bootvar__1 = lazy (
  # 15 "lib/devices/argv.ml"
    return (Mirage_bootvar.argv ())
  );;
  # 94 "mirage/main.ml"
  
  let struct_end__2 = lazy (
    let __mirage_bootvar__1 = Lazy.force mirage_bootvar__1 in
    __mirage_bootvar__1 >>= fun _mirage_bootvar__1 ->
  # 47 "lib/functoria/job.ml"
    return Mirage_runtime.(with_argv (runtime_args ()) "random" _mirage_bootvar__1)
  );;
  # 102 "mirage/main.ml"
  
  let printexc__3 = lazy (
    let _mirage_runtime_backtrace = (mirage_runtime_backtrace__key ()) in
  # 392 "lib/mirage.ml"
    return (Printexc.record_backtrace _mirage_runtime_backtrace)
  );;
  # 109 "mirage/main.ml"
  
  let hashtbl__4 = lazy (
    let _mirage_runtime_randomize_hashtables = (mirage_runtime_randomize_hashtables__key ()) in
  # 401 "lib/mirage.ml"
    return (if _mirage_runtime_randomize_hashtables then Hashtbl.randomize ())
  );;
  # 116 "mirage/main.ml"
  
  let gc__5 = lazy (
    let _mirage_runtime_allocation_policy = (mirage_runtime_allocation_policy__key ()) in
    let _mirage_runtime_minor_heap_size = (mirage_runtime_minor_heap_size__key ()) in
    let _mirage_runtime_major_heap_increment = (mirage_runtime_major_heap_increment__key ()) in
    let _mirage_runtime_space_overhead = (mirage_runtime_space_overhead__key ()) in
    let _mirage_runtime_max_space_overhead = (mirage_runtime_max_space_overhead__key ()) in
    let _mirage_runtime_gc_verbosity = (mirage_runtime_gc_verbosity__key ()) in
    let _mirage_runtime_gc_window_size = (mirage_runtime_gc_window_size__key ()) in
    let _mirage_runtime_custom_major_ratio = (mirage_runtime_custom_major_ratio__key ()) in
    let _mirage_runtime_custom_minor_ratio = (mirage_runtime_custom_minor_ratio__key ()) in
    let _mirage_runtime_custom_minor_max_size = (mirage_runtime_custom_minor_max_size__key ()) in
  # 453 "lib/mirage.ml"
    return (
  let open Gc in
    let ctrl = get () in
    set ({ ctrl with allocation_policy = (match _mirage_runtime_allocation_policy with `Next_fit -> 0 | `First_fit -> 1 | `Best_fit -> 2);
    minor_heap_size = (match _mirage_runtime_minor_heap_size with None -> ctrl.minor_heap_size | Some x -> x);
    major_heap_increment = (match _mirage_runtime_major_heap_increment with None -> ctrl.major_heap_increment | Some x -> x);
    space_overhead = (match _mirage_runtime_space_overhead with None -> ctrl.space_overhead | Some x -> x);
    max_overhead = (match _mirage_runtime_max_space_overhead with None -> ctrl.max_overhead | Some x -> x);
    verbose = (match _mirage_runtime_gc_verbosity with None -> ctrl.verbose | Some x -> x);
    window_size = (match _mirage_runtime_gc_window_size with None -> ctrl.window_size | Some x -> x);
    custom_major_ratio = (match _mirage_runtime_custom_major_ratio with None -> ctrl.custom_major_ratio | Some x -> x);
    custom_minor_ratio = (match _mirage_runtime_custom_minor_ratio with None -> ctrl.custom_minor_ratio | Some x -> x);
    custom_minor_max_size = (match _mirage_runtime_custom_minor_max_size with None -> ctrl.custom_minor_max_size | Some x -> x) })
  )
  );;
  # 145 "mirage/main.ml"
  
  let mirage_time__6 = lazy (
    return ()
  );;
  # 150 "mirage/main.ml"
  
  let mirage_runtime__7 = lazy (
    let __mirage_time__6 = Lazy.force mirage_time__6 in
    __mirage_time__6 >>= fun _mirage_time__6 ->
    let _mirage_runtime_delay = (mirage_runtime_delay__key ()) in
  # 296 "lib/mirage.ml"
    Mirage_time.sleep_ns (Duration.of_sec _mirage_runtime_delay)
  );;
  # 159 "mirage/main.ml"
  
  let pclock__8 = lazy (
    return ()
  );;
  # 164 "mirage/main.ml"
  
  let mirage_logs_make__9 = lazy (
    let __pclock__8 = Lazy.force pclock__8 in
    __pclock__8 >>= fun _pclock__8 ->
    let _mirage_runtime_logs = (mirage_runtime_logs__key ()) in
  # 22 "lib/devices/reporter.ml"
    let reporter = Mirage_logs_make__9.create () in
    Mirage_runtime.set_level ~default:(Some Logs.Info) _mirage_runtime_logs;
    Logs.set_reporter reporter;
    Lwt.return reporter
  );;
  # 176 "mirage/main.ml"
  
  let mclock__10 = lazy (
    return ()
  );;
  # 181 "mirage/main.ml"
  
  let mirage_crypto_rng_mirage_make__11 = lazy (
    let __mclock__10 = Lazy.force mclock__10 in
    let __mirage_time__6 = Lazy.force mirage_time__6 in
    __mclock__10 >>= fun _mclock__10 ->
    __mirage_time__6 >>= fun _mirage_time__6 ->
  # 15 "lib/devices/random.ml"
    Mirage_crypto_rng_mirage_make__11.initialize (module Mirage_crypto_rng.Fortuna)
  );;
  # 191 "mirage/main.ml"
  
  let app_make__12 = lazy (
    let __mirage_crypto_rng_mirage_make__11 = Lazy.force mirage_crypto_rng_mirage_make__11 in
    __mirage_crypto_rng_mirage_make__11 >>= fun _mirage_crypto_rng_mirage_make__11 ->
  # 3 "config.ml"
    (App_make__12.start _mirage_crypto_rng_mirage_make__11 : unit io)
  );;
  # 199 "mirage/main.ml"
  
  let mirage_runtime__13 = lazy (
    let __struct_end__2 = Lazy.force struct_end__2 in
    let __printexc__3 = Lazy.force printexc__3 in
    let __hashtbl__4 = Lazy.force hashtbl__4 in
    let __gc__5 = Lazy.force gc__5 in
    let __mirage_runtime__7 = Lazy.force mirage_runtime__7 in
    let __mirage_logs_make__9 = Lazy.force mirage_logs_make__9 in
    let __app_make__12 = Lazy.force app_make__12 in
    __struct_end__2 >>= fun _struct_end__2 ->
    __printexc__3 >>= fun _printexc__3 ->
    __hashtbl__4 >>= fun _hashtbl__4 ->
    __gc__5 >>= fun _gc__5 ->
    __mirage_runtime__7 >>= fun _mirage_runtime__7 ->
    __mirage_logs_make__9 >>= fun _mirage_logs_make__9 ->
    __app_make__12 >>= fun _app_make__12 ->
  # 380 "lib/mirage.ml"
    return ()
  );;
  # 219 "mirage/main.ml"
  
  let () =
    let t = Lazy.force struct_end__2 >>= fun _ ->
    Lazy.force printexc__3 >>= fun _ ->
    Lazy.force hashtbl__4 >>= fun _ ->
    Lazy.force gc__5 >>= fun _ ->
    Lazy.force mirage_runtime__7 >>= fun _ ->
    Lazy.force mirage_logs_make__9 >>= fun _ ->
    Lazy.force mirage_runtime__13 in
    run t
  ;;

  $ mirage clean


Configure the project for Xen:

  $ mirage configure -t xen
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
  let run t = Xen_os.Main.run t ; exit
  0
  
  let mirage_runtime_delay__key = Mirage_runtime.register @@
  # 33 "lib/devices/runtime_arg.ml"
    Mirage_runtime.delay
  ;;
  
  let mirage_runtime_backtrace__key = Mirage_runtime.register @@
  # 34 "lib/devices/runtime_arg.ml"
    Mirage_runtime.backtrace
  ;;
  
  let mirage_runtime_randomize_hashtables__key = Mirage_runtime.register @@
  # 35 "lib/devices/runtime_arg.ml"
    Mirage_runtime.randomize_hashtables
  ;;
  
  let mirage_runtime_allocation_policy__key = Mirage_runtime.register @@
  # 36 "lib/devices/runtime_arg.ml"
    Mirage_runtime.allocation_policy
  ;;
  
  let mirage_runtime_minor_heap_size__key = Mirage_runtime.register @@
  # 37 "lib/devices/runtime_arg.ml"
    Mirage_runtime.minor_heap_size
  ;;
  
  let mirage_runtime_major_heap_increment__key = Mirage_runtime.register @@
  # 38 "lib/devices/runtime_arg.ml"
    Mirage_runtime.major_heap_increment
  ;;
  
  let mirage_runtime_space_overhead__key = Mirage_runtime.register @@
  # 39 "lib/devices/runtime_arg.ml"
    Mirage_runtime.space_overhead
  ;;
  
  let mirage_runtime_max_space_overhead__key = Mirage_runtime.register @@
  # 40 "lib/devices/runtime_arg.ml"
    Mirage_runtime.max_space_overhead
  ;;
  
  let mirage_runtime_gc_verbosity__key = Mirage_runtime.register @@
  # 41 "lib/devices/runtime_arg.ml"
    Mirage_runtime.gc_verbosity
  ;;
  
  let mirage_runtime_gc_window_size__key = Mirage_runtime.register @@
  # 42 "lib/devices/runtime_arg.ml"
    Mirage_runtime.gc_window_size
  ;;
  
  let mirage_runtime_custom_major_ratio__key = Mirage_runtime.register @@
  # 43 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_major_ratio
  ;;
  
  let mirage_runtime_custom_minor_ratio__key = Mirage_runtime.register @@
  # 44 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_minor_ratio
  ;;
  
  let mirage_runtime_custom_minor_max_size__key = Mirage_runtime.register @@
  # 45 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_minor_max_size
  ;;
  
  let mirage_runtime_logs__key = Mirage_runtime.register @@
  # 143 "lib/devices/runtime_arg.ml"
    Mirage_runtime.logs
  ;;
  
  # 78 "mirage/main.ml"
  
  module Mirage_logs_make__9 = Mirage_logs.Make(Pclock)
  
  # 82 "mirage/main.ml"
  
  module Mirage_crypto_rng_mirage_make__11 = Mirage_crypto_rng_mirage.Make(Mclock)
  
  # 86 "mirage/main.ml"
  
  module App_make__12 = App.Make(Mirage_crypto_rng_mirage_make__11)
  
  let mirage_bootvar__1 = lazy (
  # 15 "lib/devices/argv.ml"
    return (Mirage_bootvar.argv ())
  );;
  # 94 "mirage/main.ml"
  
  let struct_end__2 = lazy (
    let __mirage_bootvar__1 = Lazy.force mirage_bootvar__1 in
    __mirage_bootvar__1 >>= fun _mirage_bootvar__1 ->
  # 47 "lib/functoria/job.ml"
    return Mirage_runtime.(with_argv (runtime_args ()) "random" _mirage_bootvar__1)
  );;
  # 102 "mirage/main.ml"
  
  let printexc__3 = lazy (
    let _mirage_runtime_backtrace = (mirage_runtime_backtrace__key ()) in
  # 392 "lib/mirage.ml"
    return (Printexc.record_backtrace _mirage_runtime_backtrace)
  );;
  # 109 "mirage/main.ml"
  
  let hashtbl__4 = lazy (
    let _mirage_runtime_randomize_hashtables = (mirage_runtime_randomize_hashtables__key ()) in
  # 401 "lib/mirage.ml"
    return (if _mirage_runtime_randomize_hashtables then Hashtbl.randomize ())
  );;
  # 116 "mirage/main.ml"
  
  let gc__5 = lazy (
    let _mirage_runtime_allocation_policy = (mirage_runtime_allocation_policy__key ()) in
    let _mirage_runtime_minor_heap_size = (mirage_runtime_minor_heap_size__key ()) in
    let _mirage_runtime_major_heap_increment = (mirage_runtime_major_heap_increment__key ()) in
    let _mirage_runtime_space_overhead = (mirage_runtime_space_overhead__key ()) in
    let _mirage_runtime_max_space_overhead = (mirage_runtime_max_space_overhead__key ()) in
    let _mirage_runtime_gc_verbosity = (mirage_runtime_gc_verbosity__key ()) in
    let _mirage_runtime_gc_window_size = (mirage_runtime_gc_window_size__key ()) in
    let _mirage_runtime_custom_major_ratio = (mirage_runtime_custom_major_ratio__key ()) in
    let _mirage_runtime_custom_minor_ratio = (mirage_runtime_custom_minor_ratio__key ()) in
    let _mirage_runtime_custom_minor_max_size = (mirage_runtime_custom_minor_max_size__key ()) in
  # 453 "lib/mirage.ml"
    return (
  let open Gc in
    let ctrl = get () in
    set ({ ctrl with allocation_policy = (match _mirage_runtime_allocation_policy with `Next_fit -> 0 | `First_fit -> 1 | `Best_fit -> 2);
    minor_heap_size = (match _mirage_runtime_minor_heap_size with None -> ctrl.minor_heap_size | Some x -> x);
    major_heap_increment = (match _mirage_runtime_major_heap_increment with None -> ctrl.major_heap_increment | Some x -> x);
    space_overhead = (match _mirage_runtime_space_overhead with None -> ctrl.space_overhead | Some x -> x);
    max_overhead = (match _mirage_runtime_max_space_overhead with None -> ctrl.max_overhead | Some x -> x);
    verbose = (match _mirage_runtime_gc_verbosity with None -> ctrl.verbose | Some x -> x);
    window_size = (match _mirage_runtime_gc_window_size with None -> ctrl.window_size | Some x -> x);
    custom_major_ratio = (match _mirage_runtime_custom_major_ratio with None -> ctrl.custom_major_ratio | Some x -> x);
    custom_minor_ratio = (match _mirage_runtime_custom_minor_ratio with None -> ctrl.custom_minor_ratio | Some x -> x);
    custom_minor_max_size = (match _mirage_runtime_custom_minor_max_size with None -> ctrl.custom_minor_max_size | Some x -> x) })
  )
  );;
  # 145 "mirage/main.ml"
  
  let mirage_time__6 = lazy (
    return ()
  );;
  # 150 "mirage/main.ml"
  
  let mirage_runtime__7 = lazy (
    let __mirage_time__6 = Lazy.force mirage_time__6 in
    __mirage_time__6 >>= fun _mirage_time__6 ->
    let _mirage_runtime_delay = (mirage_runtime_delay__key ()) in
  # 296 "lib/mirage.ml"
    Mirage_time.sleep_ns (Duration.of_sec _mirage_runtime_delay)
  );;
  # 159 "mirage/main.ml"
  
  let pclock__8 = lazy (
    return ()
  );;
  # 164 "mirage/main.ml"
  
  let mirage_logs_make__9 = lazy (
    let __pclock__8 = Lazy.force pclock__8 in
    __pclock__8 >>= fun _pclock__8 ->
    let _mirage_runtime_logs = (mirage_runtime_logs__key ()) in
  # 22 "lib/devices/reporter.ml"
    let reporter = Mirage_logs_make__9.create () in
    Mirage_runtime.set_level ~default:(Some Logs.Info) _mirage_runtime_logs;
    Logs.set_reporter reporter;
    Lwt.return reporter
  );;
  # 176 "mirage/main.ml"
  
  let mclock__10 = lazy (
    return ()
  );;
  # 181 "mirage/main.ml"
  
  let mirage_crypto_rng_mirage_make__11 = lazy (
    let __mclock__10 = Lazy.force mclock__10 in
    let __mirage_time__6 = Lazy.force mirage_time__6 in
    __mclock__10 >>= fun _mclock__10 ->
    __mirage_time__6 >>= fun _mirage_time__6 ->
  # 15 "lib/devices/random.ml"
    Mirage_crypto_rng_mirage_make__11.initialize (module Mirage_crypto_rng.Fortuna)
  );;
  # 191 "mirage/main.ml"
  
  let app_make__12 = lazy (
    let __mirage_crypto_rng_mirage_make__11 = Lazy.force mirage_crypto_rng_mirage_make__11 in
    __mirage_crypto_rng_mirage_make__11 >>= fun _mirage_crypto_rng_mirage_make__11 ->
  # 3 "config.ml"
    (App_make__12.start _mirage_crypto_rng_mirage_make__11 : unit io)
  );;
  # 199 "mirage/main.ml"
  
  let mirage_runtime__13 = lazy (
    let __struct_end__2 = Lazy.force struct_end__2 in
    let __printexc__3 = Lazy.force printexc__3 in
    let __hashtbl__4 = Lazy.force hashtbl__4 in
    let __gc__5 = Lazy.force gc__5 in
    let __mirage_runtime__7 = Lazy.force mirage_runtime__7 in
    let __mirage_logs_make__9 = Lazy.force mirage_logs_make__9 in
    let __app_make__12 = Lazy.force app_make__12 in
    __struct_end__2 >>= fun _struct_end__2 ->
    __printexc__3 >>= fun _printexc__3 ->
    __hashtbl__4 >>= fun _hashtbl__4 ->
    __gc__5 >>= fun _gc__5 ->
    __mirage_runtime__7 >>= fun _mirage_runtime__7 ->
    __mirage_logs_make__9 >>= fun _mirage_logs_make__9 ->
    __app_make__12 >>= fun _app_make__12 ->
  # 380 "lib/mirage.ml"
    return ()
  );;
  # 219 "mirage/main.ml"
  
  let () =
    let t = Lazy.force struct_end__2 >>= fun _ ->
    Lazy.force printexc__3 >>= fun _ ->
    Lazy.force hashtbl__4 >>= fun _ ->
    Lazy.force gc__5 >>= fun _ ->
    Lazy.force mirage_runtime__7 >>= fun _ ->
    Lazy.force mirage_logs_make__9 >>= fun _ ->
    Lazy.force mirage_runtime__13 in
    run t
  ;;

  $ mirage clean
