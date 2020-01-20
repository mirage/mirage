open Rresult
module Key = Functoria_key

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

let output i = match Functoria.Info.output i with None -> "main" | Some o -> o

let run cmd =
  match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
  | Error (`Msg e) -> failwith e
  | Ok (out, status) -> (
      match snd status with
      | `Exited 0 -> ()
      | `Exited _ | `Signaled _ ->
          Format.fprintf Format.str_formatter "error while executing %a\n%s"
            Bos.Cmd.pp cmd out;
          let err = Format.flush_str_formatter () in
          failwith err )

let rec root path =
  Bos.OS.File.exists Fpath.(path / "functoria-runtime.opam") >>= function
  | true -> Ok path
  | false -> root (Fpath.parent path)

let root () = R.get_ok @@ (Bos.OS.Dir.current () >>= root)

let dune_file i = Fpath.(Functoria.Info.build_dir i / "dune.build")

let write_key i k f =
  let context = Functoria.Info.context i in
  let file = Key.(name @@ abstract k) in
  let contents = f (Key.get context k) in
  R.get_ok @@ Bos.OS.File.write Fpath.(v file) contents

let split_root () =
  let cwd = R.get_ok @@ Bos.OS.Dir.current () in
  let root = root () in
  match Fpath.relativize ~root cwd with
  | None -> failwith "split root"
  | Some path -> (root, path)

module C = struct
  let prelude = "let (>>=) x f = f x\nlet return x = x\nlet run x = x"

  let name = "test"

  let version = "1.0"

  let packages = [ Functoria.package "functoria"; Functoria.package "f0" ]

  let ignore_dirs = []

  let keys = Key.[ abstract vote; abstract warn_error ]

  let connect _ _ _ = "()"

  let configure i =
    let dune =
      Fmt.strf
        "(executable\n\
        \   (name      %s)\n\
        \   (modules (:standard \\ config))\n\
        \   (libraries cmdliner fmt functoria-runtime))\n"
        (output i)
    in
    Bos.OS.File.write (dune_file i) dune

  let build i =
    Bos.OS.Dir.with_current
      (Functoria.Info.build_dir i)
      (fun () ->
        let root, prefix = split_root () in
        let exe = Fpath.((prefix / output i) + "exe") in
        write_key i vote (fun x -> x);
        write_key i warn_error string_of_bool;
        ( run
        @@ Bos.Cmd.(
             v "dune" % "build" % "--root" % Fpath.to_string root % p exe) );
        run
        @@ Bos.Cmd.(
             v "mv"
             % p Fpath.(root / "_build" / "default" // exe)
             % (output i ^ ".exe")))
      ()

  let clean i =
    Bos.OS.File.delete (dune_file i) >>= fun () ->
    Bos.OS.File.delete Fpath.(v @@ output i ^ ".exe") >>= fun () ->
    List.fold_left
      (fun acc key ->
        acc >>= fun () ->
        let file = Fpath.v (Key.name key) in
        Bos.OS.File.delete file)
      (Ok ()) keys

  let create jobs =
    let packages = Functoria.[ package "fmt" ] in
    let extra_deps = List.map Functoria.abstract jobs in
    Functoria.impl ~keys ~packages ~configure ~connect ~clean ~build ~extra_deps
      "F0" Functoria.job
end

include Functoria_app.Make (C)
