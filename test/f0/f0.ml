open Functoria
module Key = Key
open Action.Infix

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

let rec root path =
  let build = Fpath.(basename (parent path)) = "_build" in
  Action.is_file Fpath.(path / "functoria-runtime.opam") >>= fun opam ->
  match build || opam with
  | true -> Action.ok path
  | false ->
      let parent = Fpath.parent path in
      if Fpath.is_root parent then Action.ok path else root parent

let root () = Action.pwd () >>= root

let dune_build = Fpath.(v "dune.build")

let file_of_key k = Fpath.v Key.(name @@ v k)

let write_key i k f =
  let context = Info.context i in
  let file = file_of_key k in
  let contents = f (Key.get context k) in
  Action.write_file file contents

let split_root () =
  Action.pwd () >>= fun cwd ->
  root () >>= fun root ->
  match Fpath.relativize ~root cwd with
  | None -> Action.error "split root"
  | Some path -> Action.ok (root, path)

module C = struct
  open Action.Infix

  let prelude = "let (>>=) x f = f x\nlet return x = x\nlet run x = x"

  let name = "test"

  let version = "1.0~test"

  let packages = [ package "functoria"; package "f0" ]

  let keys = Key.[ v vote; v warn_error ]

  let connect _ _ _ = "()"

  let configure i =
    let dune =
      Fmt.strf
        "(executable\n\
        \   (name      %s)\n\
        \   (modules   (:standard \\ config))\n\
        \   (promote   (until-clean))\n\
        \   (libraries cmdliner fmt functoria-runtime))\n"
        (output i)
    in
    Action.write_file dune_build dune

  let build i =
    split_root () >>= fun (root, prefix) ->
    let exe = Fpath.((prefix / output i) + "exe") in
    write_key i vote (fun x -> x) >>= fun () ->
    write_key i warn_error string_of_bool >>= fun () ->
    Action.run_cmd
    @@ Bos.Cmd.(v "dune" % "build" % "--root" % Fpath.to_string root % p exe)

  let clean i =
    Action.rm dune_build >>= fun () ->
    Action.rm Fpath.(v @@ output i ^ ".exe") >>= fun () ->
    Action.List.iter
      ~f:(fun key ->
        let file = Fpath.v (Key.name key) in
        Action.rm file)
      keys

  let install i =
    match Action.run @@ split_root () with
    | Error _ -> Install.empty
    | Ok (_, prefix) ->
        let src = Fpath.((prefix / output i) + "exe") in
        let dst =
          match Info.output i with None -> Info.name i | Some o -> o
        in
        let dst = Fpath.v dst in
        let vote = Fpath.(prefix // file_of_key vote) in
        let warn_error = Fpath.(prefix // file_of_key warn_error) in
        Install.v ~bin:[ (src, dst) ] ~etc:[ vote; warn_error ] ()

  let create jobs =
    let packages = [ package "fmt" ] in
    let extra_deps = List.map dep jobs in
    impl ~keys ~packages ~configure ~connect ~clean ~build ~extra_deps ~install
      "F0" job
end

include Lib.Make (C)
module Tool = Tool.Make (C)
