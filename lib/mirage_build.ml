open Rresult
open Astring
open Mirage_impl_misc
open Mirage_link

module Key = Mirage_key
module Info = Functoria.Info

let check_entropy libs =
  query_ocamlfind ~recursive:true libs >>= fun ps ->
  if List.mem "nocrypto" ps && not (Mirage_impl_random.is_entropy_enabled ()) then
    R.error_msg
      {___|The nocrypto library is loaded but entropy is not enabled! \
       Please enable the entropy by adding a dependency to the nocrypto \
       device. You can do so by adding ~deps:[abstract nocrypto] \
       to the arguments of Mirage.foreign.|___}
  else
    R.ok ()

(*
let compile ignore_dirs libs warn_error target =
  let tags =
    [ Fmt.strf "predicate(%s)" (backend_predicate target);
      "warn(A-4-41-42-44-48)";
      "debug";
      "bin_annot";
      "strict_sequence";
      "principal";
      "safe_string" ] @
    (if warn_error then ["warn_error(+1..49)"] else []) @
    (match target with `MacOSX | `Unix -> ["thread"] | _ -> []) @
    (if terminal () then ["color(always)"] else [])
  and result = match target with
    | #Mirage_key.mode_unix -> "main.native"
    | #Mirage_key.mode_xen | #Mirage_key.mode_solo5 -> "main.native.o"
  and cflags = [ "-g" ]
  and lflags =
    let dontlink =
      match target with
      | #Mirage_key.mode_xen | #Mirage_key.mode_solo5 ->
        ["unix"; "str"; "num"; "threads"]
      | #Mirage_key.mode_unix -> []
    in
    let dont = List.map (fun k -> [ "-dontlink" ; k ]) dontlink in
    "-g" :: List.flatten dont
  in
  let concat = String.concat ~sep:"," in
  let ignore_dirs = match ignore_dirs with
    | [] -> Bos.Cmd.empty
    | dirs  -> Bos.Cmd.(v "-Xs" % concat dirs)
  in
  let want_quiet_build = match Logs.level () with
  | Some Info | Some Debug -> false
  | _ -> true
  in
  let cmd = Bos.Cmd.(v "ocamlbuild" % "-use-ocamlfind" %
                     "-classic-display" %%
                     on want_quiet_build (v "-quiet") %
                     "-tags" % concat tags %
                     "-pkgs" % concat libs %
                     "-cflags" % concat cflags %
                     "-lflags" % concat lflags %
                     "-tag-line" % "<static*.*>: warn(-32-34)" %%
                     ignore_dirs %
                     result)
  in
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Bos.OS.Cmd.run cmd
*)

let ignore_dirs = ["_build-solo5-hvt"; "_build-ukvm"]

let cross_compile = fun _ -> None

let compile target =
  let target_name = Fmt.to_to_string Key.pp_target target in
  let cmd = match cross_compile target with
    | None -> Bos.Cmd.(v "dune" % "build" % ("@" ^ target_name))
    | Some b -> Bos.Cmd.(v "dune" % "build" % ("@" ^ target_name) % "-x" % b) in
  Log.info (fun m -> m "Executing %a" Bos.Cmd.pp cmd) ;
  Bos.OS.Cmd.run cmd

let build i =
  let name = Info.name i in
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  let libs = Info.libraries i in
  let target_debug = Key.(get ctx target_debug) in
  check_entropy libs >>= fun () ->
  compile target >>= fun () ->
  link i name target target_debug >>| fun () ->
  Log.info (fun m -> m "Build succeeded.")
