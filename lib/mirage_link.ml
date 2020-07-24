open Rresult
open Astring
open Mirage_impl_misc

module Key = Mirage_key
module Info = Functoria.Info

let static_libs pkg_config_deps =
  pkg_config pkg_config_deps [ "--static" ; "--libs" ]

let ldflags pkg = pkg_config pkg ["--variable=ldflags"]

let ldpostflags pkg = pkg_config pkg ["--variable=ldpostflags"]

let find_ld pkg =
  match pkg_config pkg ["--variable=ld"] with
  | Ok (ld::_) ->
    Log.info (fun m -> m "using %s as ld (pkg-config %s --variable=ld)" ld pkg);
    ld
  | Ok [] ->
    Log.warn
      (fun m -> m "pkg-config %s --variable=ld returned nothing, using ld" pkg);
    "ld"
  | Error msg ->
    Log.warn (fun m -> m "error %a while pkg-config %s --variable=ld, using ld"
                 Rresult.R.pp_msg msg pkg);
    "ld"

let link info name target _target_debug =
  let libs = Info.libraries info in
  match target with
  | #Mirage_key.mode_unix ->
    let link = Bos.Cmd.(v "ln" % "-nfs" % "_build/main.native" % name) in
    Bos.OS.Cmd.run link >>= fun () ->
    Ok name
  | #Mirage_key.mode_solo5 | #Mirage_key.mode_xen ->
    let bindings, post = Mirage_configure_solo5.solo5_bindings_pkg target in
    let platform = Mirage_configure_solo5.solo5_platform_pkg target in
    extra_c_artifacts "freestanding" libs >>= fun c_artifacts ->
    static_libs platform
    >>= fun static_libs ->
    ldflags bindings >>= fun ldflags ->
    ldpostflags bindings >>= fun ldpostflags ->
    let out = name ^ post in
    let ld = find_ld bindings in
    let linker =
      Bos.Cmd.(v ld %% of_list ldflags % "_build/main.native.o" %
               "_build/manifest.o" %%
               of_list c_artifacts %% of_list static_libs % "-o" % out
               %% of_list ldpostflags)
    in
    Log.info (fun m -> m "linking with %a" Bos.Cmd.pp linker);
    Bos.OS.Cmd.run linker >>= fun () ->
    Ok out


