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

  let dune i =
    let dune =
      Dune.stanzaf
        {|
(executable
  (public_name f0)
  (package   functoria)
  (name      %s)
  (modules   (:standard \ config))
  (promote   (until-clean))
  (libraries cmdliner fmt functoria-runtime))
|}
        Fpath.(basename @@ rem_ext @@ Info.main i)
    in
    [ dune ]

  let configure i =
    let* () = write_key i vote (fun x -> x) in
    write_key i warn_error string_of_bool

  let create jobs =
    let packages = [ package "fmt" ] in
    let extra_deps = List.map dep jobs in
    impl ~keys ~packages ~connect ~dune ~configure ~extra_deps
      ~install:(fun _ -> Install.v ~bin:[ Fpath.(v "f0.exe", v "f0") ] ())
      "F0" job

  let name_of_target i = Info.name i

  let dune_project = []

  let dune_workspace = None

  let context_name _ = "default"
end

include Lib.Make (C)
module Tool = Tool.Make (C)
