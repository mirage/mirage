(* A very simple engine *)

open Functoria
module Key = Key

let warn_error =
  let doc = "Enable -warn-error when compiling OCaml sources." in
  let doc = Key.Arg.info ~docv:"BOOL" ~doc [ "warn-error" ] in
  let key = Key.Arg.(opt ~stage:`Configure bool false doc) in
  Key.create "warn_error" key

let vote =
  let doc = "Vote." in
  let doc = Key.Arg.info ~docv:"VOTE" ~doc [ "vote" ] in
  let key = Key.Arg.(opt ~stage:`Configure string "cat" doc) in
  Key.create "vote" key

let output i = match Info.output i with None -> "main" | Some o -> o

let file_of_key k = Fpath.v Key.(name @@ v k)

let write_key i k f =
  let context = Info.context i in
  let file = file_of_key k in
  let contents = f (Key.get context k) in
  Action.write_file file contents

module C = struct
  open Action.Syntax

  let prelude = ""

  let name = "test"

  let version = "1.0~test"

  let packages = [ package "functoria"; package "f0" ]

  let keys = Key.[ v vote; v warn_error ]

  let connect _ _ _ = "()"

  let configure _ = Action.ok ()

  let build i =
    let* () = write_key i vote (fun x -> x) in
    let* () = write_key i warn_error string_of_bool in
    Action.ok ()

  let clean _ = Action.ok ()

  let install i =
    let src = Fpath.((v "src" / output i) + "exe") in
    let dst = match Info.output i with None -> Info.name i | Some o -> o in
    let dst = Fpath.v dst in
    let vote = Fpath.(v "key" // file_of_key vote) in
    let warn_error = Fpath.(v "key" // file_of_key warn_error) in
    Install.v ~bin:[ (src, dst) ] ~etc:[ vote; warn_error ] ()

  let create jobs =
    let packages = [ package "fmt" ] in
    let extra_deps = List.map dep jobs in
    impl ~keys ~packages ~configure ~connect ~clean ~build ~extra_deps ~install
      "F0" job
end

include Lib.Make (C)
module Tool = Tool.Make (C)
