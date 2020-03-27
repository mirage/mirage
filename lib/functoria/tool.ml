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
  let build_dir args = Fpath.parent args.Cli.config_file

  let auto_generated =
    Fmt.str ";; %s"
      (Codegen.generated_header ~argv:[| P.name ^ "." ^ P.version |] ())

  let can_overwrite file =
    Action.is_file file >>= function
    | false -> Action.ok true
    | true ->
        if Fpath.basename file = "dune-project" then
          Action.read_file file >|= fun x ->
          let x = String.cuts ~sep:"\n" ~empty:true x in
          match List.rev x with x :: _ -> x = auto_generated | _ -> false
        else
          Action.read_file file >|= fun x ->
          String.is_infix ~affix:auto_generated x

  let generate ~file ~contents =
    can_overwrite file >>= function
    | false -> Action.ok ()
    | true -> Action.rm file >>= fun () -> Action.write_file file contents

  (* Generate a `dune.config` file in the build directory. *)
  let generate_dune_config args =
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
    let config_file = Fpath.(basename (rem_ext args.Cli.config_file)) in
    let contents =
      Fmt.strf
        {|%s

(executable
  (name config)
  (flags (:standard -warn-error -A))
  (modules %s)
  (libraries %s))
|}
        auto_generated config_file pkgs
    in
    generate ~file ~contents

  (* Generate a `dune.config` file in the build directory. *)
  let generate_empty_dune_build () =
    let file = Fpath.v "dune.build" in
    let contents = auto_generated ^ "\n" in
    generate ~file ~contents

  (* Generate a `dune` file in the build directory. *)
  let generate_dune () =
    let file = Fpath.v "dune" in
    let contents =
      Fmt.strf "%s\n\n(include dune.config)\n\n(include dune.build)\n"
        auto_generated
    in
    generate ~file ~contents

  (* Generate a `dune-project` file at the project root. *)
  let generate_dune_project () =
    let file = Fpath.(v "dune-project") in
    let contents = Fmt.strf "(lang dune 1.1)\n%s\n" auto_generated in
    generate ~file ~contents

  (* Generate the configuration files in the the build directory *)
  let generate_configuration_files args =
    Log.info (fun m -> m "Compiling: %a" Fpath.pp args.Cli.config_file);
    (Action.is_file args.Cli.config_file >>= function
     | true -> Action.ok ()
     | false ->
         Action.errorf "configuration file %a missing" Fpath.pp
           args.Cli.config_file)
    >>= fun () ->
    generate_dune_project () >>= fun () ->
    Action.with_dir (build_dir args) (fun () ->
        generate_dune_config args >>= fun () ->
        generate_empty_dune_build () >>= fun () -> generate_dune ())

  (* Compile the configuration files and execute it. *)
  let build_and_execute t ?help_ppf ?err_ppf argv =
    generate_configuration_files t >>= fun () ->
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
    match help_ppf with
    | None -> Action.run_cmd command
    | Some help_ppf ->
        Action.run_cmd_out ?err:err_ppf command >|= fun output ->
        Fmt.pf help_ppf "%s%!" output

  let exit_err args = function
    | Ok v -> v
    | Error (`Msg m) ->
        flush_all ();
        if m <> "" then Fmt.epr "%a\n%!" Fmt.(styled (`Fg `Red) string) m;
        if not args.Cli.dry_run then exit 1 else Fmt.epr "(exit 1)\n%!"

  let handle_parse_args_no_config ?help_ppf ?err_ppf (`Msg error) argv =
    let base_context =
      (* Extract all the keys directly. Useful to pre-resolve the keys
         provided by the specialized DSL. *)
      let base_keys = Engine.all_keys @@ Device_graph.create (P.create []) in
      Cmdliner.Term.(
        pure (fun _ -> Action.ok ())
        $ Key.context base_keys ~with_required:false ~stage:`Configure)
    in
    let niet = Cmdliner.Term.pure (Action.ok ()) in
    let result =
      Cli.eval ?help_ppf ?err_ppf ~name:P.name ~version:P.version
        ~configure:niet ~query:niet ~describe:niet ~build:niet ~clean:niet
        ~help:base_context argv
    in
    let ok = Action.ok () in
    let error = Action.error error in
    match result with
    | `Error _ -> error
    | `Version | `Help -> ok
    | `Ok (Cli.Help _) -> ok
    | `Ok
        ( Cli.Configure _ | Cli.Query _ | Cli.Describe _ | Cli.Build _
        | Cli.Clean _ ) ->
        error

  let global_env = ref None

  let action_run args a =
    if not args.Cli.dry_run then Action.run a
    else
      let env =
        match !global_env with
        | Some e -> e
        | None ->
            let commands cmd =
              match Bos.Cmd.line_exec cmd with
              | Some "dune" -> Some ("[...]", "")
              | _ -> None
            in
            let e =
              Action.env ~commands ~files:(`Passtrough (Fpath.v ".")) ()
            in
            global_env := Some e;
            e
      in
      let r, e, lines = Action.dry_run ~env a in
      global_env := Some e;
      List.iter
        (fun line ->
          Fmt.epr "%a %s\n%!" Fmt.(styled (`Fg `Cyan) string) "*" line)
        lines;
      r

  let run_with_argv ?help_ppf ?err_ppf argv =
    (* 1. Pre-parse the arguments set the log level, config file
       and root directory. *)
    let args = Cli.peek_args ~with_setup:true argv in

    (* 2. Build the config from the config file. *)
    (* There are three possible outcomes:
         1. the config file is found and built successfully
         2. no config file is specified
         3. an attempt is made to access the base keys at this point.
            when they weren't loaded *)
    build_and_execute args ?help_ppf ?err_ppf argv |> action_run args
    |> function
    | Ok () -> ()
    | Error (`Msg _ as err) ->
        handle_parse_args_no_config ?help_ppf ?err_ppf err argv
        |> action_run args
        |> exit_err args

  let run () = run_with_argv Sys.argv
end
