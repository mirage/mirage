open Functoria
open Action.Infix
open Astring
open Mirage_impl_misc
module Key = Mirage_key
module Info = Functoria.Info

let compile ignore_dirs libs warn_error target =
  let tags =
    [
      "warn(A-4-41-42-44-48)";
      "debug";
      "bin_annot";
      "strict_sequence";
      "principal";
      "safe_string";
    ]
    @ (if warn_error then [ "warn_error(+1..49)" ] else [])
    @ Mirage_target.ocamlbuild_tags target
    @ if terminal () then [ "color(always)" ] else []
  and result = Mirage_target.result target
  and cflags = [ "-g" ]
  and lflags =
    let dontlink = Mirage_target.dontlink target in
    let dont = List.map (fun k -> [ "-dontlink"; k ]) dontlink in
    "-g" :: List.flatten dont
  in
  let concat = String.concat ~sep:"," in
  let ignore_dirs =
    match ignore_dirs with
    | [] -> Bos.Cmd.empty
    | dirs -> Bos.Cmd.(v "-Xs" % concat dirs)
  in
  let want_quiet_build =
    match Logs.level () with Some Info | Some Debug -> false | _ -> true
  in
  let cmd =
    Bos.Cmd.(
      v "ocamlbuild"
      % "-use-ocamlfind"
      % "-classic-display"
      %% on want_quiet_build (v "-quiet")
      % "-tags"
      % concat tags
      % "-pkgs"
      % concat libs
      % "-cflags"
      % concat cflags
      % "-lflags"
      % concat lflags
      % "-tag-line"
      % "<static*.*>: warn(-32-34)"
      %% ignore_dirs
      % result)
  in
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Action.run_cmd cmd

let ignore_dirs = [ "_build-solo5-hvt"; "_build-ukvm" ]

let build i =
  let name = Info.name i in
  let ctx = Info.context i in
  let warn_error = Key.(get ctx warn_error) in
  let target = Key.(get ctx target) in
  let libs = Info.libraries i in
  compile ignore_dirs libs warn_error target >>= fun () ->
  Mirage_target.build i >>= fun () ->
  Mirage_target.link ~name i >|= fun out ->
  Log.info (fun m -> m "Build succeeded: %s" out)

let files i =
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  [ Fpath.v (Mirage_target.result target) ]
