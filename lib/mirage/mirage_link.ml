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
  | #Mirage_key.mode_xen ->
      extra_c_artifacts "xen" libs >>= fun c_artifacts ->
      static_libs "mirage-xen" >>= fun static_libs ->
      let linker =
        Bos.Cmd.(
          v "ld"
          % "-d"
          % "-static"
          % "-nostdlib"
          % "_build/main.native.o"
          %% of_list c_artifacts
          %% of_list static_libs)
      in
      let out = name ^ ".xen" in
      let uname_cmd = Bos.Cmd.(v "uname" % "-m") in
      Action.run_cmd_out uname_cmd >>= fun machine ->
      if String.is_prefix ~affix:"arm" machine then (
        (* On ARM:
           - we must convert the ELF image to an ARM boot executable zImage,
             while on x86 we leave it as it is.
           - we need to link libgcc.a (otherwise we get undefined references to:
             __aeabi_dcmpge, __aeabi_dadd, ...) *)
        let libgcc_cmd = Bos.Cmd.(v "gcc" % "-print-libgcc-file-name") in
        Action.run_cmd_out libgcc_cmd >>= fun libgcc ->
        let elf = name ^ ".elf" in
        let link = Bos.Cmd.(linker % libgcc % "-o" % elf) in
        Log.info (fun m -> m "linking with %a" Bos.Cmd.pp link);
        Action.run_cmd link >>= fun () ->
        let objcopy_cmd = Bos.Cmd.(v "objcopy" % "-O" % "binary" % elf % out) in
        Action.run_cmd objcopy_cmd >|= fun () -> out )
      else
        let link = Bos.Cmd.(linker % "-o" % out) in
        Log.info (fun m -> m "linking with %a" Bos.Cmd.pp link);
        Action.run_cmd link >|= fun () -> out
  | #Mirage_key.mode_solo5 ->
      let pkg, post = Mirage_configure_solo5.solo5_pkg target in
      extra_c_artifacts "freestanding" libs >>= fun c_artifacts ->
      static_libs "mirage-solo5" >>= fun static_libs ->
      ldflags pkg >>= fun ldflags ->
      ldpostflags pkg >>= fun ldpostflags ->
      let out = name ^ post in
      find_ld pkg >>= fun ld ->
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
