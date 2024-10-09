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
  let run t = Unix_os.Main.run t ; exit
  0
  
  let mirage_runtime_delay__key = Mirage_runtime.register_arg @@
  # 33 "lib/devices/runtime_arg.ml"
    Mirage_runtime.delay
  ;;
  
  let mirage_runtime_backtrace__key = Mirage_runtime.register_arg @@
  # 34 "lib/devices/runtime_arg.ml"
    Mirage_runtime.backtrace
  ;;
  
  let mirage_runtime_randomize_hashtables__key = Mirage_runtime.register_arg @@
  # 35 "lib/devices/runtime_arg.ml"
    Mirage_runtime.randomize_hashtables
  ;;
  
  let mirage_runtime_allocation_policy__key = Mirage_runtime.register_arg @@
  # 36 "lib/devices/runtime_arg.ml"
    Mirage_runtime.allocation_policy
  ;;
  
  let mirage_runtime_minor_heap_size__key = Mirage_runtime.register_arg @@
  # 37 "lib/devices/runtime_arg.ml"
    Mirage_runtime.minor_heap_size
  ;;
  
  let mirage_runtime_major_heap_increment__key = Mirage_runtime.register_arg @@
  # 38 "lib/devices/runtime_arg.ml"
    Mirage_runtime.major_heap_increment
  ;;
  
  let mirage_runtime_space_overhead__key = Mirage_runtime.register_arg @@
  # 39 "lib/devices/runtime_arg.ml"
    Mirage_runtime.space_overhead
  ;;
  
  let mirage_runtime_max_space_overhead__key = Mirage_runtime.register_arg @@
  # 40 "lib/devices/runtime_arg.ml"
    Mirage_runtime.max_space_overhead
  ;;
  
  let mirage_runtime_gc_verbosity__key = Mirage_runtime.register_arg @@
  # 41 "lib/devices/runtime_arg.ml"
    Mirage_runtime.gc_verbosity
  ;;
  
  let mirage_runtime_gc_window_size__key = Mirage_runtime.register_arg @@
  # 42 "lib/devices/runtime_arg.ml"
    Mirage_runtime.gc_window_size
  ;;
  
  let mirage_runtime_custom_major_ratio__key = Mirage_runtime.register_arg @@
  # 43 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_major_ratio
  ;;
  
  let mirage_runtime_custom_minor_ratio__key = Mirage_runtime.register_arg @@
  # 44 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_minor_ratio
  ;;
  
  let mirage_runtime_custom_minor_max_size__key = Mirage_runtime.register_arg @@
  # 45 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_minor_max_size
  ;;
  
  let mirage_runtime_logs__key = Mirage_runtime.register_arg @@
  # 208 "lib/devices/runtime_arg.ml"
    Mirage_runtime.logs
  ;;
  
  # 78 "mirage/main.ml"
  
  module App_make__13 = App.Make(Unit)
  
  let mirage_bootvar__1 = lazy (
  # 15 "lib/devices/argv.ml"
    return (Mirage_bootvar.argv ())
  );;
  # 86 "mirage/main.ml"
  
  let struct_end__2 = lazy (
    let __mirage_bootvar__1 = Lazy.force mirage_bootvar__1 in
    __mirage_bootvar__1 >>= fun _mirage_bootvar__1 ->
  # 47 "lib/functoria/job.ml"
    return Mirage_runtime.(with_argv (runtime_args ()) "random" _mirage_bootvar__1)
  );;
  # 94 "mirage/main.ml"
  
  let printexc__3 = lazy (
    let _mirage_runtime_backtrace = (mirage_runtime_backtrace__key ()) in
  # 389 "lib/mirage.ml"
    return (Printexc.record_backtrace _mirage_runtime_backtrace)
  );;
  # 101 "mirage/main.ml"
  
  let hashtbl__4 = lazy (
    let _mirage_runtime_randomize_hashtables = (mirage_runtime_randomize_hashtables__key ()) in
  # 398 "lib/mirage.ml"
    return (if _mirage_runtime_randomize_hashtables then Hashtbl.randomize ())
  );;
  # 108 "mirage/main.ml"
  
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
  # 450 "lib/mirage.ml"
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
  # 137 "mirage/main.ml"
  
  let mirage_runtime__6 = lazy (
    let _mirage_runtime_delay = (mirage_runtime_delay__key ()) in
  # 294 "lib/mirage.ml"
    Unix_os.Time.sleep_ns (Duration.of_sec _mirage_runtime_delay)
  );;
  # 144 "mirage/main.ml"
  
  let mirage_logs__7 = lazy (
    let _mirage_runtime_logs = (mirage_runtime_logs__key ()) in
  # 21 "lib/devices/reporter.ml"
    let reporter = Mirage_logs.create () in
    Mirage_runtime.set_level ~default:(Some Logs.Info) _mirage_runtime_logs;
    Logs.set_reporter reporter;
    Lwt.return reporter
  );;
  # 154 "mirage/main.ml"
  
  let mirage_timer__8 = lazy (
    return ()
  );;
  # 159 "mirage/main.ml"
  
  let mirage_clock__9 = lazy (
    return ()
  );;
  # 164 "mirage/main.ml"
  
  let mirage_time__10 = lazy (
    return ()
  );;
  # 169 "mirage/main.ml"
  
  let mirage_crypto_rng_mirage__11 = lazy (
  # 13 "lib/devices/random.ml"
    Mirage_crypto_rng_mirage.initialize (module Mirage_crypto_rng.Fortuna)
  );;
  # 175 "mirage/main.ml"
  
  let unit__12 = lazy (
    return ()
  );;
  # 180 "mirage/main.ml"
  
  let app_make__13 = lazy (
    let __unit__12 = Lazy.force unit__12 in
    __unit__12 >>= fun _unit__12 ->
  # 3 "config.ml"
    (App_make__13.start _unit__12 : unit io)
  );;
  # 188 "mirage/main.ml"
  
  let mirage_runtime__14 = lazy (
    let __struct_end__2 = Lazy.force struct_end__2 in
    let __printexc__3 = Lazy.force printexc__3 in
    let __hashtbl__4 = Lazy.force hashtbl__4 in
    let __gc__5 = Lazy.force gc__5 in
    let __mirage_runtime__6 = Lazy.force mirage_runtime__6 in
    let __mirage_logs__7 = Lazy.force mirage_logs__7 in
    let __mirage_timer__8 = Lazy.force mirage_timer__8 in
    let __mirage_clock__9 = Lazy.force mirage_clock__9 in
    let __mirage_time__10 = Lazy.force mirage_time__10 in
    let __mirage_crypto_rng_mirage__11 = Lazy.force mirage_crypto_rng_mirage__11 in
    let __app_make__13 = Lazy.force app_make__13 in
    __struct_end__2 >>= fun _struct_end__2 ->
    __printexc__3 >>= fun _printexc__3 ->
    __hashtbl__4 >>= fun _hashtbl__4 ->
    __gc__5 >>= fun _gc__5 ->
    __mirage_runtime__6 >>= fun _mirage_runtime__6 ->
    __mirage_logs__7 >>= fun _mirage_logs__7 ->
    __mirage_timer__8 >>= fun _mirage_timer__8 ->
    __mirage_clock__9 >>= fun _mirage_clock__9 ->
    __mirage_time__10 >>= fun _mirage_time__10 ->
    __mirage_crypto_rng_mirage__11 >>= fun _mirage_crypto_rng_mirage__11 ->
    __app_make__13 >>= fun _app_make__13 ->
  # 377 "lib/mirage.ml"
    return ()
  );;
  # 216 "mirage/main.ml"
  
  let () =
    let t = Lazy.force struct_end__2 >>= fun _ ->
    Lazy.force printexc__3 >>= fun _ ->
    Lazy.force hashtbl__4 >>= fun _ ->
    Lazy.force gc__5 >>= fun _ ->
    Lazy.force mirage_runtime__6 >>= fun _ ->
    Lazy.force mirage_logs__7 >>= fun _ ->
    Lazy.force mirage_timer__8 >>= fun _ ->
    Lazy.force mirage_clock__9 >>= fun _ ->
    Lazy.force mirage_time__10 >>= fun _ ->
    Lazy.force mirage_crypto_rng_mirage__11 >>= fun _ ->
    Lazy.force mirage_runtime__14 in
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
  let run t = Xen_os.Main.run t ; exit
  0
  
  let mirage_runtime_delay__key = Mirage_runtime.register_arg @@
  # 33 "lib/devices/runtime_arg.ml"
    Mirage_runtime.delay
  ;;
  
  let mirage_runtime_backtrace__key = Mirage_runtime.register_arg @@
  # 34 "lib/devices/runtime_arg.ml"
    Mirage_runtime.backtrace
  ;;
  
  let mirage_runtime_randomize_hashtables__key = Mirage_runtime.register_arg @@
  # 35 "lib/devices/runtime_arg.ml"
    Mirage_runtime.randomize_hashtables
  ;;
  
  let mirage_runtime_allocation_policy__key = Mirage_runtime.register_arg @@
  # 36 "lib/devices/runtime_arg.ml"
    Mirage_runtime.allocation_policy
  ;;
  
  let mirage_runtime_minor_heap_size__key = Mirage_runtime.register_arg @@
  # 37 "lib/devices/runtime_arg.ml"
    Mirage_runtime.minor_heap_size
  ;;
  
  let mirage_runtime_major_heap_increment__key = Mirage_runtime.register_arg @@
  # 38 "lib/devices/runtime_arg.ml"
    Mirage_runtime.major_heap_increment
  ;;
  
  let mirage_runtime_space_overhead__key = Mirage_runtime.register_arg @@
  # 39 "lib/devices/runtime_arg.ml"
    Mirage_runtime.space_overhead
  ;;
  
  let mirage_runtime_max_space_overhead__key = Mirage_runtime.register_arg @@
  # 40 "lib/devices/runtime_arg.ml"
    Mirage_runtime.max_space_overhead
  ;;
  
  let mirage_runtime_gc_verbosity__key = Mirage_runtime.register_arg @@
  # 41 "lib/devices/runtime_arg.ml"
    Mirage_runtime.gc_verbosity
  ;;
  
  let mirage_runtime_gc_window_size__key = Mirage_runtime.register_arg @@
  # 42 "lib/devices/runtime_arg.ml"
    Mirage_runtime.gc_window_size
  ;;
  
  let mirage_runtime_custom_major_ratio__key = Mirage_runtime.register_arg @@
  # 43 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_major_ratio
  ;;
  
  let mirage_runtime_custom_minor_ratio__key = Mirage_runtime.register_arg @@
  # 44 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_minor_ratio
  ;;
  
  let mirage_runtime_custom_minor_max_size__key = Mirage_runtime.register_arg @@
  # 45 "lib/devices/runtime_arg.ml"
    Mirage_runtime.custom_minor_max_size
  ;;
  
  let mirage_runtime_logs__key = Mirage_runtime.register_arg @@
  # 208 "lib/devices/runtime_arg.ml"
    Mirage_runtime.logs
  ;;
  
  # 78 "mirage/main.ml"
  
  module App_make__13 = App.Make(Unit)
  
  let mirage_bootvar__1 = lazy (
  # 15 "lib/devices/argv.ml"
    return (Mirage_bootvar.argv ())
  );;
  # 86 "mirage/main.ml"
  
  let struct_end__2 = lazy (
    let __mirage_bootvar__1 = Lazy.force mirage_bootvar__1 in
    __mirage_bootvar__1 >>= fun _mirage_bootvar__1 ->
  # 47 "lib/functoria/job.ml"
    return Mirage_runtime.(with_argv (runtime_args ()) "random" _mirage_bootvar__1)
  );;
  # 94 "mirage/main.ml"
  
  let printexc__3 = lazy (
    let _mirage_runtime_backtrace = (mirage_runtime_backtrace__key ()) in
  # 389 "lib/mirage.ml"
    return (Printexc.record_backtrace _mirage_runtime_backtrace)
  );;
  # 101 "mirage/main.ml"
  
  let hashtbl__4 = lazy (
    let _mirage_runtime_randomize_hashtables = (mirage_runtime_randomize_hashtables__key ()) in
  # 398 "lib/mirage.ml"
    return (if _mirage_runtime_randomize_hashtables then Hashtbl.randomize ())
  );;
  # 108 "mirage/main.ml"
  
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
  # 450 "lib/mirage.ml"
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
  # 137 "mirage/main.ml"
  
  let mirage_runtime__6 = lazy (
    let _mirage_runtime_delay = (mirage_runtime_delay__key ()) in
  # 294 "lib/mirage.ml"
    Xen_os.Time.sleep_ns (Duration.of_sec _mirage_runtime_delay)
  );;
  # 144 "mirage/main.ml"
  
  let mirage_logs__7 = lazy (
    let _mirage_runtime_logs = (mirage_runtime_logs__key ()) in
  # 21 "lib/devices/reporter.ml"
    let reporter = Mirage_logs.create () in
    Mirage_runtime.set_level ~default:(Some Logs.Info) _mirage_runtime_logs;
    Logs.set_reporter reporter;
    Lwt.return reporter
  );;
  # 154 "mirage/main.ml"
  
  let mirage_timer__8 = lazy (
    return ()
  );;
  # 159 "mirage/main.ml"
  
  let mirage_clock__9 = lazy (
    return ()
  );;
  # 164 "mirage/main.ml"
  
  let mirage_time__10 = lazy (
    return ()
  );;
  # 169 "mirage/main.ml"
  
  let mirage_crypto_rng_mirage__11 = lazy (
  # 13 "lib/devices/random.ml"
    Mirage_crypto_rng_mirage.initialize (module Mirage_crypto_rng.Fortuna)
  );;
  # 175 "mirage/main.ml"
  
  let unit__12 = lazy (
    return ()
  );;
  # 180 "mirage/main.ml"
  
  let app_make__13 = lazy (
    let __unit__12 = Lazy.force unit__12 in
    __unit__12 >>= fun _unit__12 ->
  # 3 "config.ml"
    (App_make__13.start _unit__12 : unit io)
  );;
  # 188 "mirage/main.ml"
  
  let mirage_runtime__14 = lazy (
    let __struct_end__2 = Lazy.force struct_end__2 in
    let __printexc__3 = Lazy.force printexc__3 in
    let __hashtbl__4 = Lazy.force hashtbl__4 in
    let __gc__5 = Lazy.force gc__5 in
    let __mirage_runtime__6 = Lazy.force mirage_runtime__6 in
    let __mirage_logs__7 = Lazy.force mirage_logs__7 in
    let __mirage_timer__8 = Lazy.force mirage_timer__8 in
    let __mirage_clock__9 = Lazy.force mirage_clock__9 in
    let __mirage_time__10 = Lazy.force mirage_time__10 in
    let __mirage_crypto_rng_mirage__11 = Lazy.force mirage_crypto_rng_mirage__11 in
    let __app_make__13 = Lazy.force app_make__13 in
    __struct_end__2 >>= fun _struct_end__2 ->
    __printexc__3 >>= fun _printexc__3 ->
    __hashtbl__4 >>= fun _hashtbl__4 ->
    __gc__5 >>= fun _gc__5 ->
    __mirage_runtime__6 >>= fun _mirage_runtime__6 ->
    __mirage_logs__7 >>= fun _mirage_logs__7 ->
    __mirage_timer__8 >>= fun _mirage_timer__8 ->
    __mirage_clock__9 >>= fun _mirage_clock__9 ->
    __mirage_time__10 >>= fun _mirage_time__10 ->
    __mirage_crypto_rng_mirage__11 >>= fun _mirage_crypto_rng_mirage__11 ->
    __app_make__13 >>= fun _app_make__13 ->
  # 377 "lib/mirage.ml"
    return ()
  );;
  # 216 "mirage/main.ml"
  
  let () =
    let t = Lazy.force struct_end__2 >>= fun _ ->
    Lazy.force printexc__3 >>= fun _ ->
    Lazy.force hashtbl__4 >>= fun _ ->
    Lazy.force gc__5 >>= fun _ ->
    Lazy.force mirage_runtime__6 >>= fun _ ->
    Lazy.force mirage_logs__7 >>= fun _ ->
    Lazy.force mirage_timer__8 >>= fun _ ->
    Lazy.force mirage_clock__9 >>= fun _ ->
    Lazy.force mirage_time__10 >>= fun _ ->
    Lazy.force mirage_crypto_rng_mirage__11 >>= fun _ ->
    Lazy.force mirage_runtime__14 in
    run t
  ;;

  $ mirage clean
