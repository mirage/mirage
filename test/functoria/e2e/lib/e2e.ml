open Functoria
open Cmdliner
module Key = Key

let docs = "APPLICATION OPTIONS"

let warn_error =
  let doc = "Enable -warn-error when compiling OCaml sources." in
  let doc = Arg.info ~docv:"BOOL" ~doc ~docs [ "warn-error" ] in
  let key = Key.Arg.opt Arg.bool false doc in
  Key.create "warn_error" key

let vote =
  let doc = "Vote." in
  let doc = Arg.info ~docv:"VOTE" ~doc ~docs [ "vote" ] in
  let key = Key.Arg.opt Arg.string "cat" doc in
  Key.create "vote" key

let file_of_key k = Fpath.v Key.(name @@ v k)

let write_key i k f =
  let context = Info.context i in
  let file = file_of_key k in
  let contents = f (Key.get context k) in
  Action.write_file file contents

module C = struct
  open Action.Syntax

  let prelude _ =
    "let (>>=) x f = f x\ntype 'a io = 'a\nlet return x = x\nlet run x = x"

  let name = "test"
  let version = "1.0~test"
  let packages = [ package ~sublibs:[ "functoria" ] "mirage"; package "e2e" ]
  let keys = Key.[ v vote; v warn_error ]
  let connect _ _ _ = code ~pos:__POS__ "()"
  let main i = Fpath.(basename @@ rem_ext @@ Info.main i)
  let config i = Fpath.(basename @@ rem_ext @@ Info.config_file i)

  let dune i =
    let dune =
      Dune.stanzaf
        {|
(executable
  (name      %s)
  (modules   (:standard \ %s))
  (promote   (until-clean))
  (libraries cmdliner fmt mirage-runtime.functoria))
|}
        (main i) (config i)
    in
    [ dune ]

  let configure i =
    let* () = write_key i vote (fun x -> x) in
    write_key i warn_error string_of_bool

  let create jobs =
    let packages = [ package "fmt" ] in
    let extra_deps = List.map dep jobs in
    let install i = Install.v ~bin:[ Fpath.(v (main i) + "exe", v "e2e") ] () in
    impl ~keys ~packages ~connect ~dune ~configure ~extra_deps ~install "E2e"
      job

  let name_of_target i = Info.name i
  let target_filename = name_of_target
  let dune_project = []
  let dune_workspace = None
  let context_name _ = "default"
end

include Lib.Make (C)
include Tool.Make (C)

let register ?(init = []) ?src name typ =
  let init = runtime_args sys_argv :: init in
  register ~init ?src name typ
