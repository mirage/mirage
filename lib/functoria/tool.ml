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

  let context_file args = Context_cache.file ~name:P.name args

  let run_cmd ?ppf ?err_ppf command =
    let err = match err_ppf with None -> None | Some f -> Some (`Fmt f) in
    let out = match ppf with None -> None | Some f -> Some (`Fmt f) in
    Action.run_cmd ?err ?out command

  (* re-exec the command by calling config.exe with the same argv as
     the current command. *)
  let re_exec t ?ppf ?err_ppf argv =
    let argv = List.tl (Array.to_list argv) in
    let argv =
      match t.Cli.context_file with
      | Some _ -> Action.ok argv
      | None -> (
          Action.is_file (context_file t) >|= function
          | false -> argv
          | true -> argv @ [ "--context=" ^ Fpath.to_string (context_file t) ] )
    in
    argv >>= fun argv ->
    let args = Bos.Cmd.of_list argv in
    let command =
      Bos.Cmd.(
        v "dune" % "exec" % "--" % p Fpath.(build_dir t / "config.exe") %% args)
    in
    run_cmd ?ppf ?err_ppf command

  let re_exec_out t ?err_ppf argv =
    let buf = Buffer.create 10 in
    let ppf = Fmt.with_buffer buf in
    re_exec t ~ppf ?err_ppf argv >|= fun () -> Buffer.contents buf

  let query k t ?err_ppf _ =
    re_exec_out t ?err_ppf
      [| ""; "query"; Fmt.to_to_string Cli.pp_query_kind k |]

  (* Generate a `dune-project` file at the project root. *)
  let generate_dune_project () =
    let file = Fpath.(v "dune-project") in
    let contents = Dune.base_project in
    Filegen.write file (Fmt.str "%a\n" Dune.pp contents)

  let generate_makefile ~depext name =
    let file = Fpath.(v "Makefile") in
    let contents = Fmt.to_to_string Makefile.pp (Makefile.v ~depext name) in
    Filegen.write file contents

  let query_name t ?err_ppf argv = query `Name t ?err_ppf argv >|= String.trim

  (* Generate the base dune and dune-project files *)
  let generate_base_dune t =
    Log.info (fun m ->
        m "Generating: %a (base)" Fpath.pp Fpath.(build_dir t / "dune"));
    let dune = Dune.base ~packages:P.packages ~name:P.name ~version:P.version in
    let dune = Fmt.str "%a\n%!" Dune.pp dune in
    Filegen.write Fpath.(build_dir t / "dune") dune

  let build_config_exe t ?ppf ?err_ppf () =
    let command =
      Bos.Cmd.(v "dune" % "build" % p Fpath.(build_dir t / "config.exe"))
    in
    run_cmd ?ppf ?err_ppf command

  let generate_opam ~name t ?err_ppf () =
    query `Opam t ?err_ppf () >>= fun contents ->
    let file = Fpath.(v name + ".opam") in
    Log.info (fun m -> m "Generating: %a (opam)" Fpath.pp file);
    Filegen.write file contents

  let generate_dune alias t ?err_ppf () =
    let file =
      match alias with
      | `Full | `Base -> Fpath.(build_dir t / "dune")
      | `Workspace -> Fpath.(v "dune-workspace")
      | `Project -> Fpath.(v "dune-project")
    in
    Log.info (fun m ->
        m "Generating: %a (%a)" Fpath.pp file Cli.pp_query_kind (`Dune alias));
    query (`Dune alias) t ?err_ppf () >>= fun contents ->
    Filegen.write file contents

  let write_context t argv = Context_cache.write (context_file t) argv

  let remove_context t = Action.rm (context_file t)

  (* Generated a project skeleton and try to compile config.exe. *)
  let generate_project_skeleton ~save_args t ?ppf ?err_ppf argv =
    generate_dune_project () >>= fun () ->
    generate_base_dune t >>= fun () ->
    (if save_args then write_context t argv else Action.ok ()) >>= fun () ->
    (* try to compile config.exe to detect early compilation errors. *)
    build_config_exe t ?ppf ?err_ppf ()

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
      let base_keys = Engine.all_keys @@ Device_graph.create (P.create []) in
      Cmdliner.Term.(
        pure (fun _ -> Action.ok ())
        $ Key.context base_keys ~with_required:false ~stage:`Configure)
    in
    let result =
      Cli.eval ?help_ppf ?err_ppf ~name:P.name ~version:P.version
        ~configure:context ~query:context ~describe:context ~build:context
        ~clean:context ~help:context argv
    in
    let ok = Action.ok () in
    let error = Action.error error in
    match result with `Version | `Help | `Ok (Cli.Help _) -> ok | _ -> error

  let with_project_skeleton ~save_args t ?ppf ?err_ppf argv f =
    let file = t.Cli.config_file in
    Action.is_file file >>= function
    | false ->
        let msg = Fmt.str "configuration file %a missing" Fpath.pp file in
        handle_parse_args_no_config ?help_ppf:ppf ?err_ppf (`Msg msg) argv
    | true -> generate_project_skeleton ~save_args t ?ppf ?err_ppf argv >>= f

  let action_run t a =
    if not t.Cli.dry_run then Action.run a
    else
      let env =
        let commands cmd =
          match Bos.Cmd.line_exec cmd with
          | Some "dune" -> Some (Fmt.str "$(%a)\n" Bos.Cmd.pp cmd, "")
          | _ -> None
        in
        Action.env ~commands ~files:(`Passtrough (Fpath.v ".")) ()
      in
      let r, _, lines = Action.dry_run ~env a in
      List.iter
        (fun line ->
          Fmt.epr "%a %s\n%!" Fmt.(styled (`Fg `Cyan) string) "*" line)
        lines;
      r

  let clean_files ?ppf ?err_ppf args =
    Action.ls (Fpath.v ".") (fun file ->
        Fpath.parent file = Fpath.v "./"
        &&
        let base, ext = Fpath.split_ext file in
        let base = Fpath.basename base in
        match (base, ext) with
        | _, (".opam" | ".install") -> true
        | ("Makefile" | "dune-project" | "dune-worspace"), "" -> true
        | _ -> false)
    >>= fun files ->
    Action.List.iter ~f:Filegen.rm files >>= fun () ->
    remove_context args >>= fun () ->
    Filegen.rm Fpath.(build_dir args / "dune") >>= fun () ->
    Action.rm Fpath.(build_dir args / ".merlin") >>= fun () ->
    Action.get_var "INSIDE_FUNCTORIA_TESTS" >>= function
    | Some "1" | Some "" -> Action.ok ()
    | _ -> run_cmd ?ppf ?err_ppf Bos.Cmd.(v "dune" % "clean")

  let with_alias ~save_args args depext ?ppf ?err_ppf argv =
    with_project_skeleton ~save_args args ?ppf ?err_ppf argv @@ fun () ->
    query_name args ?err_ppf () >>= fun name ->
    let name = String.trim name in
    generate_opam ~name args ?err_ppf () >>= fun () ->
    generate_makefile ~depext name >>= fun () ->
    generate_dune `Project args ?err_ppf () >>= fun () ->
    generate_dune `Workspace args ?err_ppf () >>= fun () ->
    generate_dune `Full args ?err_ppf ()

  let configure ({ args; depext } : _ Cli.configure_args) ?ppf ?err_ppf argv =
    with_alias ~save_args:true args depext ?ppf ?err_ppf argv

  let build (args : _ Cli.build_args) ?ppf ?err_ppf _argv =
    Fmt.epr "Deprecated: use `dune buid' directly\n%!";
    let path = build_dir args in
    let cmd = Bos.Cmd.(v "dune" % "build" % p path) in
    run_cmd ?ppf ?err_ppf cmd

  let try_to_re_exec args ?ppf ?err_ppf argv =
    with_project_skeleton ~save_args:false args ?ppf ?err_ppf argv @@ fun () ->
    re_exec args ?ppf ?err_ppf argv

  let error t = try_to_re_exec t

  let query (t : 'a Cli.query_args) = try_to_re_exec t.args

  let describe (t : 'a Cli.describe_args) = try_to_re_exec t.args

  let help (t : 'a Cli.help_args) = try_to_re_exec t

  let clean (t : 'a Cli.clean_args) ?ppf ?err_ppf _argv =
    clean_files ?ppf ?err_ppf t

  let run args action = action |> action_run args |> exit_err args

  let pp_unit _ _ = ()

  let run_with_argv ?help_ppf ?err_ppf argv =
    let t = Cli.peek ~with_setup:true argv in
    match t with
    | `Version ->
        Log.info (fun l -> l "version");
        Fmt.pr "%s\n%!" P.version
    | `Error (t, _) ->
        Log.info (fun l -> l "error: %a" (Cli.pp_args pp_unit) t);
        run t @@ error t ?ppf:help_ppf ?err_ppf argv
    | `Ok t -> (
        Log.info (fun l -> l "run: %a" (Cli.pp_action pp_unit) t);
        let run = run (Cli.args t) in
        let ppf = help_ppf in
        match t with
        | Configure t -> run @@ configure t ?ppf ?err_ppf argv
        | Build t -> run @@ build t ?ppf ?err_ppf argv
        | Clean t -> run @@ clean t ?ppf ?err_ppf argv
        | Query t -> run @@ query t ?ppf ?err_ppf argv
        | Describe t -> run @@ describe t ?ppf ?err_ppf argv
        | Help t -> run @@ help t ?ppf ?err_ppf argv )

  let run () = run_with_argv Sys.argv
end
