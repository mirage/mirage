open Rresult
open Astring
open Mirage_impl_misc

module Key = Mirage_key
module Info = Functoria.Info

let static_libs pkg_config_deps =
  pkg_config pkg_config_deps [ "--static" ; "--libs" ] >>| fun s ->
  String.cuts ~sep:" " ~empty:false s

let ld target =
  solo5_config target ["--ld"] >>= fun s ->
  Rresult.R.open_error_msg (Bos.Cmd.of_string s)

let ldflags target =
  solo5_config target ["--ldflags"] >>= fun s ->
  Rresult.R.open_error_msg (Bos.Cmd.of_string s)

let link info name target _target_debug =
  let libs = Info.libraries info in
  match target with
  | #Mirage_key.mode_unix ->
    let link = Bos.Cmd.(v "ln" % "-nfs" % "_build/main.native" % name) in
    Bos.OS.Cmd.run link >>= fun () ->
    Ok name
  | #Mirage_key.mode_solo5 | #Mirage_key.mode_xen ->
    let platform = Mirage_configure_solo5.solo5_platform_pkg target in
    extra_c_artifacts "freestanding" libs >>= fun c_artifacts ->
    static_libs platform >>= fun static_libs ->
    ld target >>= fun ld ->
    ldflags target >>= fun ldflags ->
    let extension = Mirage_configure_solo5.bin_extension target in
    let out = name ^ extension in
    let linker =
      Bos.Cmd.(ld %% ldflags % "_build/main.native.o" % "_build/manifest.o" %%
               of_list c_artifacts %% of_list static_libs % "-o" % out)
    in
    Log.info (fun m -> m "linking with %a" Bos.Cmd.pp linker);
    Bos.OS.Cmd.run linker >>= fun () ->
    Ok out


