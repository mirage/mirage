(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2020 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2015-2020 Gabriel Radanne <drupyog@zoho.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Astring
open Action.Infix
open DSL

let src = Logs.Src.create "functoria.tool" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

module type S = sig
  val name : string

  val version : string

  val packages : package list

  val create : job impl list -> job impl
end

module Make (P : S) = struct
  module Filegen = Filegen.Make (P)

  let build_dir t = Fpath.parent t.Cli.config_file

  let context_file args =
    match args.Cli.context_file with
    | Some f -> f
    | None ->
        let dir = Fpath.parent args.Cli.config_file in
        Fpath.(normalize (dir / (P.name ^ ".context")))

  let add_context_file t argv =
    match Cli.peek_context_file ~mname:P.name argv with
    | Some _ -> Action.ok argv
    | None -> (
        let file = context_file t in
        Action.is_file file >|= function
        | false -> argv (* should only happen when doing configure --help *)
        | true -> Array.append argv [| "--context"; Fpath.to_string file |] )

  let run_cmd ?ppf ?err_ppf command =
    let err = match err_ppf with None -> None | Some f -> Some (`Fmt f) in
    let out = match ppf with None -> None | Some f -> Some (`Fmt f) in
    Action.run_cmd ?err ?out command

  (* re-exec the command by calling config.exe with the same argv as
     the current command. Also add the [--context] argument if needed. *)
  let re_exec t ?ppf ?err_ppf argv =
    add_context_file t argv >>= fun argv ->
    let args = Bos.Cmd.of_list (List.tl (Array.to_list argv)) in
    let command =
      Bos.Cmd.(
        v "dune"
        % "exec"
        % "--root"
        % "."
        % "--"
        % p Fpath.(build_dir t / "config.exe")
        %% args)
    in
    run_cmd ?ppf ?err_ppf command

  let re_exec_out t ?err_ppf argv =
    let buf = Buffer.create 10 in
    let ppf = Fmt.with_buffer buf in
    re_exec t ~ppf ?err_ppf argv >|= fun () -> Buffer.contents buf

  let query k t ?err_ppf _argv =
    re_exec_out t ?err_ppf
      [| ""; "query"; Fmt.to_to_string Cli.pp_query_kind k |]

  (* Generate a `dune.config` file in the build directory. *)
  let generate_dune_config t =
    let file = Fpath.v "dune.config" in
    let pkgs =
      match P.packages with
      | [] -> ""
      | pkgs ->
          let pkgs =
            List.fold_left
              (fun acc pkg ->
                let pkgs = String.Set.of_list (Package.libraries pkg) in
                String.Set.union pkgs acc)
              String.Set.empty pkgs
            |> String.Set.elements
          in
          String.concat ~sep:" " pkgs
    in
    let config_file = Fpath.(basename (rem_ext t.Cli.config_file)) in
    let contents =
      Fmt.strf
        {|(executable
  (name config)
  (flags (:standard -warn-error -A))
  (modules %s)
  (libraries %s))
|}
        config_file pkgs
    in
    Filegen.write file contents

  (* Generate a `dune.build` file in the build directory. *)
  let generate_empty_dune_build () = Filegen.write (Fpath.v "dune.build") "\n"

  (* Generate a `dune` file in the build directory. *)
  let generate_dune () =
    let file = Fpath.v "dune" in
    let contents = "(include dune.config)\n\n(include dune.build)\n" in
    Filegen.write file contents

  (* Generate a `dune-project` file at the project root. *)
  let generate_dune_project () =
    let file = Fpath.(v "dune-project") in
    let contents = "(lang dune 1.1)\n" in
    Filegen.write file contents

  (* Generate the configuration files in the the build directory *)
  let generate_configuration_files t =
    Log.info (fun m -> m "Compiling: %a" Fpath.pp t.Cli.config_file);
    generate_dune_project () >>= fun () ->
    Action.with_dir (build_dir t) (fun () ->
        generate_dune_config t >>= fun () ->
        generate_empty_dune_build () >>= fun () -> generate_dune ())

  let generate_makefile ~depext name =
    let file = Fpath.(v "Makefile") in
    let contents = Fmt.to_to_string Makefile.pp (Makefile.v ~depext name) in
    Filegen.write file contents

  let query_name t ?err_ppf argv = query `Name t ?err_ppf argv >|= String.trim

  let generate_opam ~name t ?err_ppf argv =
    query `Opam t ?err_ppf argv >>= fun contents ->
    let file = Fpath.(v name + ".opam") in
    Log.info (fun m -> m "Generating: %a" Fpath.pp file);
    Filegen.write file contents

  let generate_install ~name t ?err_ppf argv =
    query `Install t ?err_ppf argv >>= fun contents ->
    let file = Fpath.(v name + ".install") in
    Log.info (fun m -> m "Generating: %a" Fpath.pp file);
    Filegen.write file contents

  let write_context t argv = Context_cache.write (context_file t) argv

  let remove_context t = Action.rm (context_file t)

  (* Generated a project skeleton and try to compile config.exe. *)
  let check_project t ?ppf ?err_ppf () =
    generate_configuration_files t >>= fun () ->
    let command =
      Bos.Cmd.(v "dune" % "build" % p Fpath.(build_dir t / "config.exe"))
    in
    run_cmd ?ppf ?err_ppf command

  let exit_err t = function
    | Ok v -> v
    | Error (`Msg m) ->
        flush_all ();
        if m <> "" then Fmt.epr "%a\n%!" Fmt.(styled (`Fg `Red) string) m;
        if not t.Cli.dry_run then exit 1 else Fmt.epr "(exit 1)\n%!"

  let handle_parse_args_no_config ?help_ppf ?err_ppf (`Msg error) argv =
    let context =
      (* Extract all the keys directly. Useful to pre-resolve the keys
         provided by the specialized DSL. *)
      let base_keys = Engine.all_keys @@ Impl.abstract @@ P.create [] in
      Cmdliner.Term.(
        pure (fun _ -> Action.ok ())
        $ Key.context base_keys ~with_required:false ~stage:`Configure)
    in
    let result =
      Cli.eval ?help_ppf ?err_ppf ~name:P.name ~version:P.version
        ~configure:context ~query:context ~describe:context ~build:context
        ~clean:context ~help:context ~mname:P.name argv
    in
    let ok = Action.ok () in
    let error = Action.error error in
    match result with `Version | `Help | `Ok (Cli.Help _) -> ok | _ -> error

  let handle_parse_args ~save_args t ?ppf ?err_ppf argv =
    let file = t.Cli.config_file in
    Action.is_file file >>= function
    | true ->
        check_project t ?ppf ?err_ppf () >>= fun () ->
        (if save_args then write_context t argv else Action.ok ()) >>= fun () ->
        re_exec t ?ppf ?err_ppf argv
    | false ->
        let msg = Fmt.str "configuration file %a missing" Fpath.pp file in
        handle_parse_args_no_config ?help_ppf:ppf ?err_ppf (`Msg msg) argv

  let action_run t a =
    if not t.Cli.dry_run then Action.run a
    else
      let env = Action.env ~files:(`Passtrough (Fpath.v ".")) () in
      let dom = Action.dry_run ~env a in
      List.iter
        (fun line ->
          Fmt.epr "%a %s\n%!" Fmt.(styled (`Fg `Cyan) string) "*" line)
        dom.logs;
      dom.result

  let clean_files args =
    Action.ls (Fpath.v ".") (fun file ->
        Fpath.parent file = Fpath.v "./"
        &&
        let base, ext = Fpath.split_ext file in
        let base = Fpath.basename base in
        match (base, ext) with
        | _, (".opam" | ".install") -> true
        | ("Makefile" | "dune-project" | "dune-workspace"), "" -> true
        | _ -> false)
    >>= fun files ->
    Action.List.iter ~f:Filegen.rm files >>= fun () ->
    remove_context args >>= fun () ->
    Action.get_var "INSIDE_FUNCTORIA_TESTS" >>= function
    | Some "1" | Some "" -> Action.ok ()
    | None -> Action.rmdir Fpath.(v "_build")
    | _ -> Action.rmdir Fpath.(v "_build")

  let error args ?help_ppf ?err_ppf argv =
    handle_parse_args args ~save_args:false ?ppf:help_ppf ?err_ppf argv

  let configure ({ args; depext } : _ Cli.configure_args) ?ppf ?err_ppf argv =
    handle_parse_args ~save_args:true args ?ppf ?err_ppf argv >>= fun () ->
    query_name args ?err_ppf argv >>= fun name ->
    generate_opam ~name args ?err_ppf argv >>= fun () ->
    generate_install ~name args ?err_ppf argv >>= fun () ->
    generate_makefile ~depext name

  let clean args ?ppf ?err_ppf argv =
    let config = args.Cli.config_file in
    (Action.is_file config >>= function
     | false -> Action.ok ()
     | true ->
         check_project args ?ppf ?err_ppf () >>= fun () ->
         re_exec args ?ppf ?err_ppf argv)
    >>= fun () -> clean_files args

  let run args action = action |> action_run args |> exit_err args

  let pp_unit _ _ = ()

  let run_with_argv ?help_ppf ?err_ppf argv =
    let t = Cli.peek ~with_setup:true ~mname:P.name argv in
    match t with
    | `Version ->
        Log.info (fun l -> l "version");
        Fmt.pr "%s\n%!" P.version
    | `Error (t, _) ->
        Log.info (fun l -> l "error: %a" (Cli.pp_args pp_unit) t);
        run t @@ error t ?help_ppf ?err_ppf argv
    | `Ok t -> (
        Log.info (fun l -> l "run: %a" (Cli.pp_action pp_unit) t);
        let args = Cli.args t in
        match t with
        | Configure t -> run args @@ configure t ?ppf:help_ppf ?err_ppf argv
        | Clean args -> run args @@ clean args ?ppf:help_ppf ?err_ppf argv
        | _ ->
            run args
            @@ handle_parse_args ~save_args:false args ?ppf:help_ppf ?err_ppf
                 argv )

  let run () = run_with_argv Sys.argv
end
