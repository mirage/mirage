open Rresult
module Key = Functoria_key

let warn_error =
  let doc = "Enable -warn-error when compiling OCaml sources." in
  let doc = Key.Arg.info ~docv:"BOOL" ~doc ["warn-error"] in
  let key = Key.Arg.(opt ~stage:`Configure bool false doc) in
  Key.create "warn_error" key

let vote =
  let doc = "Vote." in
  let doc = Key.Arg.info ~docv:"VOTE" ~doc ["vote"] in
  let key = Key.Arg.(opt ~stage:`Configure string "cat" doc) in
  Key.create "vote" key

let output i = match Functoria.Info.output i with
  | None   -> "main"
  | Some o -> o

let run cmd =
  match Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string with
  | Error (`Msg e)   -> failwith e
  | Ok (out, status) -> match snd status with
    | `Exited 0 ->  ()
    | `Exited _
    | `Signaled _ ->
      Format.fprintf Format.str_formatter "error while executing %a\n%s"
        Bos.Cmd.pp cmd out ;
      let err = Format.flush_str_formatter () in
      failwith err

let rec root path =
  Bos.OS.File.exists Fpath.(path / "functoria.opam") >>= function
  | true  -> Ok path
  | false -> root (Fpath.parent path)

let root () = R.get_ok @@ (Bos.OS.Dir.current () >>= root)

let jbuild_file i = Fpath.(Functoria.Info.build_dir i / "jbuild")

let write_key i k f =
  let context = Functoria.Info.context i in
  let file = Key.(name @@ abstract k) in
  let contents = f (Key.get context k) in
  R.get_ok @@ Bos.OS.File.write Fpath.(v file) contents

let split_root () =
  let cwd = R.get_ok @@ Bos.OS.Dir.current () in
  let root = Fpath.(root () / "_build" / "default") in
  match Fpath.relativize ~root cwd with
  | None      -> failwith "split root"
  | Some path -> root, path

module C = struct
  let prelude = "let (>>=) x f = f x\n\
                 let return x = x\n\
                 let run x = x"
  let name = "test"
  let version = "1.0"
  let packages = [Functoria.package "functoria"]
  let ignore_dirs = []

  let create jobs = Functoria.impl @@ object
      inherit Functoria.base_configurable
      method ty = Functoria.job
      method name = "test_app"
      method module_name = "Test_app"
      method! connect _ _ _ = "()"
      method! keys = [
        Functoria_key.(abstract vote);
        Functoria_key.(abstract warn_error);
      ]
      method! packages = Key.pure [
          Functoria.package "fmt";
        ]

      method! configure i =
        let jbuild = Fmt.strf
            "(jbuild_version 1)\n\
             \n\
             ; An infortunate hack: bring stage 0 modules in scope of stage 1\n\
             (rule (copy ../../runtime/functoria_runtime.ml functoria_runtime.ml))\n\
             (rule (copy ../../runtime/functoria_info.ml functoria_info.ml))\n\
             \n\
             (executable\n\
            \   ((name      %s)\n\
            \    (libraries (cmdliner fmt))))\n"
            (output i)
        in
        Bos.OS.File.write (jbuild_file i) jbuild

      method! clean i =
        Bos.OS.File.delete (jbuild_file i)

      method! build i =
        Bos.OS.Dir.with_current (Functoria.Info.build_dir i) (fun () ->
            let root, prefix = split_root () in
            let exe = Fpath.(prefix / output i + "exe") in
            write_key i vote (fun x -> x);
            write_key i warn_error string_of_bool;
            run @@ Bos.Cmd.(v "jbuilder" % "build"
                            % "--root" % Fpath.to_string root
                            % Fpath.(to_string exe));
            run @@ Bos.Cmd.(v "mv" % Fpath.(to_string @@ root / "_build" / "default" // exe)
                            % (output i ^ ".exe"));
          ) ()

      method! deps = List.map Functoria.abstract jobs
    end
end

include Functoria_app.Make(C)
