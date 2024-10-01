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

open Action.Syntax
open DSL

let src = Logs.Src.create "functoria.tool" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

module type S = sig
  val name : string
  val version : string
  val packages : package list
  val create : job impl list -> job impl
end

let check_version ~name ~version data =
  let ( let* ) = Result.bind in
  let extract_version v =
    if String.for_all (function '0' .. '9' | '.' -> true | _ -> false) v then
      try Ok (Scanf.sscanf v "%u.%u.%u" (fun ma mi pa -> (ma, mi, pa))) with
      | Scanf.Scan_failure _ | End_of_file -> (
          try Ok (Scanf.sscanf v "%u.%u" (fun ma mi -> (ma, mi, 0))) with
          | Scanf.Scan_failure _ | End_of_file -> (
              try Ok (Scanf.sscanf v "%u" (fun ma -> (ma, 0, 0)))
              with Scanf.Scan_failure _ | Failure _ | End_of_file ->
                Error ("couldn't extract version (%u) from " ^ v))
          | Failure f ->
              Error ("couldn't extract version (%u.%u) from " ^ v ^ ": " ^ f))
      | Failure f ->
          Error ("couldn't extract version (%u.%u.%u) from " ^ v ^ ": " ^ f)
    else Error "only digits and . allowed in version"
  in
  if String.equal version ("%%" ^ "VERSION%%") then (
    Log.warn (fun m ->
        m "Skipping version check, since our_version is not watermarked");
    Ok ())
  else
    match extract_version version with
    | Error msg ->
        Log.warn (fun m ->
            m
              "Skipping version check, since our_version (%S) fails to parse: \
               %s"
              version msg);
        Ok ()
    | Ok version' ->
        let first_str = "(* " ^ name ^ " " in
        let fl = String.length first_str in
        if
          fl < String.length data
          && String.equal (String.sub data 0 fl) first_str
        then
          let* lower_version, upper_version =
            let vs =
              String.split_on_char ' '
                (String.sub data fl (String.length data - fl))
            in
            let rec go lower upper = function
              | "&" :: tl -> go lower upper tl
              | ">=" :: v :: tl ->
                  if lower = None then go (Some v) upper tl
                  else Error "Bad comment, multiple >= constraints"
              | "<" :: v :: tl ->
                  if upper = None then go lower (Some v) tl
                  else Error "Bad comment, multiple < constraints"
              | "*)" :: _ -> Ok (lower, upper)
              | "" :: tl -> go lower upper tl
              | _ ->
                  Error
                    (Fmt.str
                       "Unknown first line, must be (* %s [>= a.b.c] [&] [< \
                        d.e.f] *)"
                       name)
            in
            go None None vs
          in
          let cmp ~eq (ma, mi, pa) (ma', mi', pa') =
            ma > ma'
            || (ma = ma' && mi > mi')
            || (ma = ma' && mi = mi' && pa > pa')
            || (ma = ma' && mi = mi' && pa = pa' && eq)
          in
          let* () =
            match lower_version with
            | None -> Ok ()
            | Some v ->
                let* v' = extract_version v in
                if cmp ~eq:true version' v' then Ok ()
                else
                  Error
                    (Fmt.str
                       "Version mismatch: required is %s >= %s, but %s is \
                        installed. Please upgrade your installation (opam \
                        update; opam install '%s>=%s')"
                       name v version name v)
          in
          match upper_version with
          | None -> Ok ()
          | Some v ->
              let* v' = extract_version v in
              if cmp ~eq:false v' version' then Ok ()
              else
                Error
                  (Fmt.str
                     "Version mismatch: required is %s < %s, but %s is \
                      installed. Please downgrade your installation (opam \
                      update; opam install '%s<%s')"
                     name v version name v)
        else Ok ()

module Make (P : S) = struct
  module Filegen = Filegen.Make (P)

  let build_dir t = Fpath.parent t.Cli.config_file
  let context_file t = Context_cache.file ~name:P.name t

  let add_context_file t argv =
    match t.Cli.context_file with
    | Some _ -> Action.ok argv
    | None ->
        let file = context_file t in
        let+ is_file = Action.is_file file in
        if is_file then
          Array.append argv [| "--context"; Fpath.to_string file |]
        else (* should only happen when doing configure --help *) argv

  let run_cmd ?ppf ?err_ppf command =
    let err = match err_ppf with None -> None | Some f -> Some (`Fmt f) in
    let out = match ppf with None -> None | Some f -> Some (`Fmt f) in
    Action.run_cmd ?err ?out command

  let re_exec_cli t argv =
    let* argv = add_context_file t argv in
    let args = Bos.Cmd.of_list (List.tl (Array.to_list argv)) in
    let config_exe =
      Fpath.(v "_build" / "default" // build_dir t / "config.exe")
    in
    let command = Bos.Cmd.(v (p config_exe) %% args) in
    Action.run_cmd_cli command

  (* Generate the base dune and dune-project files *)
  let generate_base_dune t =
    let dune_config_path = Fpath.(build_dir t / "dune.config") in
    Log.info (fun m -> m "Generating: %a (base)" Fpath.pp dune_config_path);
    let dune_config =
      Dune.base ~config_ml_file:t.Cli.config_file ~packages:P.packages
    in
    let dune_config = Fmt.str "%a\n%!" Dune.pp dune_config in
    let* () = Filegen.write dune_config_path dune_config in
    let dune_path = Fpath.(build_dir t / "dune") in
    let dune = Fmt.str "(include dune.config)" in
    Filegen.write dune_path dune

  let dune_workspace_path t =
    Fpath.(build_dir t / P.name / "dune-workspace.config")

  let generate_base_dune_workspace t =
    let dune_workspace_path = dune_workspace_path t in
    Log.info (fun m -> m "Generating: %a (base)" Fpath.pp dune_workspace_path);
    let dune = Dune.base_workspace in
    let dune = Fmt.str "%a\n%!" Dune.pp dune in
    Filegen.write dune_workspace_path dune

  let generate_base_dune_project () =
    let dune_project_path = Fpath.(v "dune-project") in
    Log.info (fun m -> m "Generating: %a (base)" Fpath.pp dune_project_path);
    let dune = Dune.v Dune.base_project in
    let dune = Fmt.str "%a\n%!" Dune.pp dune in
    Filegen.write dune_project_path dune

  let build_config_exe t ?ppf ?err_ppf () =
    let dune_workspace_path = dune_workspace_path t in
    let command =
      Bos.Cmd.(
        v "dune"
        % "build"
        % p Fpath.(build_dir t / "config.exe")
        % "--root"
        % "."
        % "--workspace"
        % p dune_workspace_path)
    in
    run_cmd ?ppf ?err_ppf command

  let write_context t argv = Context_cache.write (context_file t) argv
  let remove_context t = Action.rm (context_file t)

  (* Generated a project skeleton and try to compile config.exe. *)
  let generate_project_skeleton ~save_args t ?ppf ?err_ppf argv =
    let* _ = Action.mkdir Fpath.(build_dir t / P.name) in
    let* () = generate_base_dune_workspace t in
    let* () = generate_base_dune_project () in
    let* () = generate_base_dune t in
    let* () = if save_args then write_context t argv else Action.ok () in
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
      let base_keys = Engine.keys @@ Impl.abstract @@ P.create [] in
      Cmdliner.Term.(const (fun _ -> Action.ok ()) $ Key.context base_keys)
    in
    let result =
      Cli.eval ?help_ppf ?err_ppf ~name:P.name ~version:P.version
        ~configure:context ~query:context ~describe:context ~clean:context
        ~help:context ~mname:P.name argv
    in
    let ok = Action.ok () in
    let error = Action.error error in
    match result with `Version | `Help | `Ok (Cli.Help _) -> ok | _ -> error

  let with_project_skeleton ~save_args t ?ppf ?err_ppf argv f =
    let file = t.Cli.config_file in
    let* is_file = Action.is_file file in
    if not is_file then
      let msg = Fmt.str "configuration file %a missing" Fpath.pp file in
      handle_parse_args_no_config ?help_ppf:ppf ?err_ppf (`Msg msg) argv
    else
      let* () = generate_project_skeleton ~save_args t ?ppf ?err_ppf argv in
      f ()

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

  let clean_files ?ppf ?err_ppf args =
    let dune_clean () =
      let* var = Action.get_var "INSIDE_FUNCTORIA_TESTS" in
      match var with
      | Some "1" | Some "" -> Action.rm Fpath.(build_dir args / ".merlin")
      | _ -> run_cmd ?ppf ?err_ppf Bos.Cmd.(v "dune" % "clean")
    in
    let rm_gen_files () =
      let* files = Action.ls (Fpath.v ".") (fun _ -> true) in
      let files = List.sort Fpath.compare files in
      let files =
        List.filter_map
          (fun file ->
            if Fpath.parent file <> Fpath.v "./" then None
            else
              let base, ext = Fpath.split_ext file in
              let base = Fpath.basename base in
              match (base, ext) with
              | ("Makefile" | "dune-project" | "dune-workspace"), "" ->
                  Some file
              | _ ->
                  Log.info (fun f -> f "Skipped %a" Fpath.pp file);
                  None)
          files
      in
      let* () = Action.List.iter ~f:Filegen.rm files in
      let* () = remove_context args in
      let* () = Filegen.rm Fpath.(build_dir args / "dune") in
      let* () = Filegen.rm Fpath.(build_dir args / "dune.build") in
      Filegen.rm Fpath.(build_dir args / "dune.config")
    in
    let* () = dune_clean () in
    rm_gen_files ()

  (* App builder configuration *)
  let configure ({ args; _ } : _ Cli.configure_args) ?ppf ?err_ppf argv =
    let file = args.Cli.config_file in
    let* () =
      let* is_file = Action.is_file file in
      if not is_file then
        Action.errorf "configuration file %a missing" Fpath.pp file
      else Action.ok ()
    in
    let* () =
      let* data =
        let cmd = Bos.Cmd.(v "head" % "-1" % p file) in
        Action.run_cmd_out ~err:`Null cmd
      in
      let version =
        let v = P.version in
        if String.length v > 0 && String.get v 0 = 'v' then
          String.sub v 1 (String.length v - 1)
        else v
      in
      Result.fold
        ~ok:(fun () -> Action.ok ())
        ~error:(fun msg -> Action.error msg)
        (check_version ~name:P.name ~version data)
    in
    (* Files to build config.ml *)
    with_project_skeleton ~save_args:true args ?ppf ?err_ppf argv @@ fun () ->
    Log.info (fun f -> f "Set-up config skeleton.");
    (* Launch config.exe: additional generated files for the application. *)
    re_exec_cli args argv

  let try_to_re_exec args ?ppf ?err_ppf argv =
    with_project_skeleton ~save_args:false args ?ppf ?err_ppf argv @@ fun () ->
    re_exec_cli args argv

  let error t = try_to_re_exec t
  let query (t : 'a Cli.query_args) = try_to_re_exec t.args
  let describe (t : 'a Cli.describe_args) = try_to_re_exec t.args
  let help (t : 'a Cli.help_args) = try_to_re_exec t

  let clean args ?ppf ?err_ppf argv =
    let config = args.Cli.config_file in
    let* () =
      let* is_file = Action.is_file config in
      if is_file then try_to_re_exec args ?ppf ?err_ppf argv else Action.ok ()
    in
    clean_files args

  let run args action = action |> action_run args |> exit_err args
  let pp_unit _ _ = ()

  let run_with_argv ?help_ppf ?err_ppf argv =
    let t = Cli.peek ~with_setup:true ~mname:P.name argv in
    match t with
    | `Version ->
        Log.info (fun l -> l "version");
        Fmt.pr "%s\n%!" P.version
    | `Error (Some t, _) ->
        Log.info (fun l -> l "error: %a" (Cli.pp_args pp_unit) t);
        run t @@ error t ?ppf:help_ppf ?err_ppf argv
    | `Error (None, _) ->
        let action =
          handle_parse_args_no_config ?help_ppf ?err_ppf (`Msg "") argv
        in
        let args = Cli.default_args in
        action_run args action |> exit_err args
    | `Ok t -> (
        Log.info (fun l -> l "run: %a" (Cli.pp_action pp_unit) t);
        let run = run (Cli.args t) in
        let ppf = help_ppf in
        match t with
        | Configure t -> run @@ configure t ?ppf ?err_ppf argv
        | Clean t -> run @@ clean t ?ppf ?err_ppf argv
        | Query t -> run @@ query t ?ppf ?err_ppf argv
        | Describe t -> run @@ describe t ?ppf ?err_ppf argv
        | Help t -> run @@ help t ?ppf ?err_ppf argv)

  let run () = run_with_argv Sys.argv
end
