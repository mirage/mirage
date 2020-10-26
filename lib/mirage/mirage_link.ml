open Functoria
open Astring
open Mirage_impl_misc
open Action.Infix
module Key = Mirage_key
module Info = Functoria.Info

let static_libs pkg_config_deps =
  pkg_config pkg_config_deps [ "--static"; "--libs" ]

let ldflags pkg = pkg_config pkg [ "--variable=ldflags" ]

let ldpostflags pkg = pkg_config pkg [ "--variable=ldpostflags" ]

let find_ld pkg =
  pkg_config pkg [ "--variable=ld" ] >|= function
  | ld :: _ ->
      Log.info (fun m ->
          m "using %s as ld (pkg-config %s --variable=ld)" ld pkg);
      ld
  | [] ->
      Log.warn (fun m ->
          m "pkg-config %s --variable=ld returned nothing, using ld" pkg);
      "ld"

let link info name target _target_debug =
  let libs = Info.libraries info in
  match target with
  | #Mirage_key.mode_unix ->
      let link = Bos.Cmd.(v "ln" % "-nfs" % "_build/main.native" % name) in
      Action.run_cmd link >|= fun () -> name
  | #Mirage_key.mode_solo5 | #Mirage_key.mode_xen ->
      let bindings = Mirage_configure_solo5.solo5_bindings_pkg target in
      let platform = Mirage_configure_solo5.solo5_platform_pkg target in
      extra_c_artifacts "freestanding" libs >>= fun c_artifacts ->
      static_libs platform >>= fun static_libs ->
      ldflags bindings >>= fun ldflags ->
      ldpostflags bindings >>= fun ldpostflags ->
      let extension = Mirage_configure_solo5.bin_extension target in
      let out = name ^ extension in
      find_ld bindings >>= fun ld ->
      let linker =
        Bos.Cmd.(
          v ld
          %% of_list ldflags
          % "_build/main.native.o"
          % "_build/manifest.o"
          %% of_list c_artifacts
          %% of_list static_libs
          % "-o"
          % out
          %% of_list ldpostflags)
      in
      Log.info (fun m -> m "linking with %a" Bos.Cmd.pp linker);
      Action.run_cmd linker >|= fun () -> out
