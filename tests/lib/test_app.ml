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

module C = struct
  let prelude = "let (>>=) x f = f x\n\
                 let return x = x\n\
                 let run x = x"
  let name = "test"
  let version = "1.0"
  let packages = []
  let ignore_dirs = []

  let create jobs = Functoria.impl @@ object
      inherit Functoria.base_configurable
      method ty = Functoria.job
      method name = "test_app"
      method module_name = "Test_app"
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
             (executable\n\
            \   ((name      main)\n\
            \    (libraries (%a))))\n"
            Fmt.(list ~sep:(unit " ") string) Functoria.Info.(package_names i)
        in
        let file = Fpath.(Functoria.Info.root i / "jbuild") in
        Bos.OS.File.write file jbuild

      method! build i =
        let cmd = Bos.Cmd.(v "jbuilder" % "build" % "main.exe") in
        Bos.OS.Dir.with_current (Functoria.Info.root i) (fun () ->
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
          ) ()

      method! deps = List.map Functoria.abstract jobs
    end
end

include Functoria_app.Make(C)
