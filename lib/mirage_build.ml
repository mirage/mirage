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
