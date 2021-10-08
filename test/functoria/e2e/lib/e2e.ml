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

let dune_build = Fpath.(v "dune.build")

let file_of_key k = Fpath.v Key.(name @@ v k)

let write_key i k f =
  let context = Info.context i in
  let file = file_of_key k in
  let contents = f (Key.get context k) in
  Action.write_file file contents

let root =
  match Sys.getenv "DUNE_SOURCEROOT" with
  | dir -> dir
  | exception Not_found -> Sys.getcwd ()

module C = struct
  open Action.Syntax

  let prelude = "let (>>=) x f = f x\nlet return x = x\nlet run x = x"

  let name = "test"

  let version = "1.0~test"

  let packages = [ package "functoria"; package "e2e" ]

  let keys = Key.[ v vote; v warn_error ]

  let connect _ _ _ = "()"

  let configure i =
    let dune =
      Fmt.str
        "(executable\n\
        \   (name      %s)\n\
        \   (modules   (:standard \\ config))\n\
        \   (promote   (until-clean))\n\
        \   (libraries cmdliner fmt functoria-runtime))\n"
        (output i)
    in
    Action.write_file dune_build dune

  let build i =
    let* () = write_key i vote (fun x -> x) in
    let* () = write_key i warn_error string_of_bool in
    Action.run_cmd
    @@ Bos.Cmd.(
         v "dune"
         % "build"
         % "--root"
         % root
         % "--no-print-directory"
         % "--display=quiet")

  let clean i =
    let* () = Action.rm dune_build in
    let* () = Action.rm Fpath.(v @@ output i ^ ".exe") in
    Action.List.iter
      ~f:(fun key ->
        let file = Fpath.v (Key.name key) in
        Action.rm file)
      keys

  let install i =
    let src = Fpath.(v (output i) + "exe") in
    let dst = match Info.output i with None -> Info.name i | Some o -> o in
    let dst = Fpath.v dst in
    let vote = file_of_key vote in
    let warn_error = file_of_key warn_error in
    Install.v ~bin:[ (src, dst) ] ~etc:[ vote; warn_error ] ()

  let create jobs =
    let packages = [ package "fmt" ] in
    let extra_deps = List.map dep jobs in
    impl ~keys ~packages ~configure ~connect ~clean ~build ~extra_deps ~install
      "F0" job
end

include Lib.Make (C)
include Tool.Make (C)
