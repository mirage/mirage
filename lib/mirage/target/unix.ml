open Functoria
open Action.Infix

type t = [ `Unix | `MacOSX ]

let cast = function `Unix -> `Unix | _ -> failwith "not an unix target"

let packages _ = [ package ~min:"4.0.0" ~max:"5.0.0" "mirage-unix" ]

let configure _ = Action.ok ()

let configure_files _ = []

let build _ = Action.ok ()

let link ~name _ =
  let link = Bos.Cmd.(v "ln" % "-nfs" % "_build/main.native" % name) in
  Action.run_cmd link >|= fun () -> name

let install i =
  let name = match Info.output i with None -> Info.name i | Some n -> n in
  let bin = (Fpath.((v "_build" / "main") + "native"), Fpath.v name) in
  Install.v ~bin:[ bin ] ~etc:[] ()

let result = "main.native"

let dontlink = []

let ocamlbuild_tags = [ "thread" ]

let clean _ = Action.ok ()
