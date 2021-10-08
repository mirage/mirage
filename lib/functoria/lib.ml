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
open Astring
open DSL
module Name = Misc.Name

let src = Logs.Src.create "functoria" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

module Config = struct
  type t = {
    name : string;
    build_cmd : string list;
    packages : package list Key.value;
    keys : Key.Set.t;
    init : job impl list;
    jobs : Impl.abstract;
    src : [ `Auto | `None | `Some of string ];
  }

  type out = {
    init : job impl list;
    jobs : Impl.abstract;
    info : Info.t;
    device_graph : Device.Graph.t;
  }

  (* In practice, we get all the keys associated to [if] cases, and
     all the keys that have a setter to them. *)
  let get_if_context jobs =
    let all_keys = Engine.all_keys jobs in
    let skeys = Engine.if_keys jobs in
    let f k s =
      if Key.Set.is_empty @@ Key.Set.inter (Key.aliases k) skeys then s
      else Key.Set.add k s
    in
    Key.Set.fold f all_keys skeys

  let v ?(keys = []) ?(packages = []) ?(init = []) ~build_cmd ~src name jobs =
    let name = Name.ocamlify name in
    let packages = Key.pure @@ packages in
    let jobs = Impl.abstract jobs in
    let keys = Key.Set.(union (of_list keys) (get_if_context jobs)) in
    { packages; keys; name; init; build_cmd; jobs; src }

  let eval ~full context
      { name = n; build_cmd; packages; keys; jobs; init; src } =
    let jobs = Impl.simplify ~full ~context jobs in
    let device_graph = Impl.eval ~context jobs in
    let packages = Key.(pure List.append $ packages $ Engine.packages jobs) in
    let keys = Key.Set.elements (Key.Set.union keys @@ Engine.all_keys jobs) in
    let mk packages _ context =
      let info = Info.v ~packages ~keys ~context ~build_cmd ~src n in
      { init; jobs; info; device_graph }
    in
    Key.(pure mk $ packages $ of_deps (Set.of_list keys))

  let keys t = t.keys

  let pp_dot = Impl.pp_dot
end

module type S = sig
  val prelude : string

  val packages : Package.t list

  val name : string

  val version : string

  val create : job impl list -> job impl

  val name_of_target : Info.t -> string

  val dune_project : Dune.stanza list

  val dune_workspace : (?build_dir:Fpath.t -> info -> Dune.t) option

  val context_name : Info.t -> string
end

module Make (P : S) = struct
  module Filegen = Filegen.Make (P)

  let default_init = [ Job.keys Argv.sys_argv ]

  let build_dir args = Fpath.parent args.Cli.config_file

  let mirage_dir args = Fpath.(build_dir args / P.name)

  let artifacts_dir = Fpath.v "dist"

  let exit_err args = function
    | Ok v -> v
    | Error (`Msg m) ->
        flush_all ();
        if m <> "" then Fmt.epr "%a\n%!" Fmt.(styled (`Fg `Red) string) m;
        if not args.Cli.dry_run then exit 1 else Fmt.epr "(exit 1)"

  let get_build_cmd _ =
    let command_line_arguments =
      Sys.argv
      |> Array.to_list
      |> List.tl
      |> List.filter (fun arg ->
             arg <> "configure" && arg <> "query" && arg <> "switch.opam")
      |> List.map (fun x -> "\"" ^ x ^ "\"")
      |> String.concat ~sep:" "
    in
    [
      Fmt.str {|"%s" "configure" %s|} P.name command_line_arguments;
      Fmt.str {|"%s" "build"|} P.name;
    ]

  (* STAGE 2 *)

  let src = Logs.Src.create (P.name ^ "-configure") ~doc:"functoria generated"

  module Log = (val Logs.src_log src : Logs.LOG)

  let eval_cached ~full ~with_required ~output ~cache context t =
    let info = Config.eval ~full context t in
    let keys = Key.deps info in
    let output =
      match (output, Context_cache.peek_output cache) with
      | Some _, _ -> output
      | _, cache -> cache
    in
    let context = Key.context ~stage:`Configure ~with_required keys in
    let context = Context_cache.merge cache context in
    let f context =
      let config = Key.eval context info context in
      match output with
      | None -> config
      | Some o -> { config with info = Info.with_output config.info o }
    in
    Cmdliner.Term.(pure f $ context)

  (* FIXME: describe init *)
  let describe (t : _ Cli.describe_args) =
    let { Config.jobs; _ } = t.args.Cli.context in
    let f fmt =
      Fmt.pf fmt "%a\n%!" (if t.dot then Config.pp_dot else Fmt.nop) jobs
    in
    let with_fmt f =
      match t.args.output with
      | None when t.dot ->
          f Format.str_formatter;
          let data = Format.flush_str_formatter () in
          let* tmp = Action.tmp_file ~mode:0o644 "graph%s.dot" in
          let* () = Action.write_file tmp data in
          Action.run_cmd Bos.Cmd.(v t.dotcmd % p tmp)
      | None -> Action.ok (f Fmt.stdout)
      | Some s -> Action.with_output ~path:(Fpath.v s) ~purpose:"dot file" f
    in
    with_fmt f

  let configure_main i init jobs =
    let main = Info.main i in
    let purpose = Fmt.str "configure: create %a" Fpath.pp main in
    Log.info (fun m -> m "Generating: %a (main file)" Fpath.pp main);
    let* () =
      Action.with_output ~path:main ~append:false ~purpose (fun ppf ->
          Fmt.pf ppf "%a@.@." Fmt.text P.prelude)
    in
    let* () = Engine.configure i jobs in
    Engine.connect i ~init jobs

  let files i jobs =
    let main = Info.main i in
    let files = Engine.files i jobs in
    let files = Fpath.Set.add main files in
    Fpath.Set.(elements files)

  let build (args : _ Cli.build_args) =
    (* Get application name *)
    let build_dir = build_dir args in
    let* () = Filegen.write Fpath.(build_dir / "dune") "(include dune.build)" in
    let cmd = Bos.Cmd.(v "dune" % "build" % "--root" % ".") in
    Log.info (fun f -> f "dune build --root .");
    Action.run_cmd_cli cmd

  let query ({ args; kind; depext; extra_repo } : _ Cli.query_args) =
    let { Config.jobs; info; _ } = args.Cli.context in
    let name = P.name_of_target info in
    let install = Key.eval (Info.context info) (Engine.install info jobs) in
    let build_dir = Fpath.parent args.config_file in
    match kind with
    | `Name -> Fmt.pr "%s\n%!" (Info.name info)
    | `Packages ->
        let pkgs = Info.packages info in
        List.iter (Fmt.pr "%a\n%!" (Package.pp ~surround:"\"")) pkgs
    | `Opam scope ->
        let opam = Info.opam ~install scope info in
        Fmt.pr "%a\n%!" Opam.pp opam
    | `Files ->
        let files = files info jobs in
        Fmt.pr "%a\n%!" Fmt.(list ~sep:(any " ") Fpath.pp) files
    | `Makefile ->
        let file =
          Makefile.v ~build_dir ~depext ~name:P.name ?extra_repo
            (Info.name info)
        in
        Fmt.pr "%a\n%!" Makefile.pp file
    | `Dune `Config ->
        let cwd = Bos.OS.Dir.current () |> Result.get_ok in
        let config_ml_file = Fpath.(cwd // args.Cli.config_file) in
        let dune =
          Dune.base ~config_ml_file ~packages:P.packages ~name:P.name
            ~version:P.version
        in
        Fmt.pr "%a\n%!" Dune.pp dune
    | `Dune `Build ->
        let dune_copy_config = Dune.stanzaf "(copy_files ./config/*)" in
        let dune = Dune.v (dune_copy_config :: Engine.dune info jobs) in
        Fmt.pr "%a\n%!" Dune.pp dune
    | `Dune `Project ->
        let dune =
          Dune.v
            (Dune.base_project
            @ (Dune.stanzaf "(name %s)" name :: P.dune_project))
        in
        Fmt.pr "%a\n%!" Dune.pp dune
    | `Dune `Workspace ->
        let dune =
          match P.dune_workspace with
          | None -> Dune.base_workspace
          | Some f -> f ~build_dir info
        in
        Fmt.pr "%a\n%!" Dune.pp dune
    | `Dune `Dist ->
        let install = Key.eval (Info.context info) (Engine.install info jobs) in
        Fmt.pr "%a\n%!" Dune.pp
          (Install.dune
             ~build_dir:Fpath.(v ".." // build_dir)
             ~context_name:(P.context_name info) install)

  (* Configuration step. *)

  let generate_opam ~name scope (args : _ Cli.args) () =
    let { Config.info; jobs; _ } = args.Cli.context in
    let install = Key.eval (Info.context info) (Engine.install info jobs) in
    let fname =
      match scope with
      | `Monorepo -> "-monorepo.opam"
      | `Switch -> "-switch.opam"
    in
    let opam = Info.opam ~install scope info in
    let contents = Fmt.str "%a" Opam.pp opam in
    let file = Fpath.(v (name ^ fname)) in
    Log.info (fun m ->
        m "Generating: %a (%a)" Fpath.pp file Cli.pp_query_kind (`Opam scope));
    Filegen.write file contents

  let generate_dune alias (args : _ Cli.args) () =
    let { Config.info; jobs; _ } = args.Cli.context in
    let name = P.name_of_target info in
    let build_dir = build_dir args in
    let file =
      match alias with
      | `Dist -> Fpath.(v "dune")
      | `Build -> Fpath.(v "dune.build")
      | `Workspace -> Fpath.(v "dune-workspace")
      | `Project -> Fpath.(v "dune-project")
    in
    Log.info (fun m ->
        m "Generating: %a (%a)" Fpath.pp file Cli.pp_query_kind
          (`Dune alias :> Cli.query_kind));
    let contents =
      match alias with
      | `Build ->
          let import_config = Dune.stanzaf "(copy_files ./%s/*)" P.name in
          let dune = Dune.v (import_config :: Engine.dune info jobs) in
          Fmt.str "%a\n" Dune.pp dune
      | `Project ->
          let dune =
            Dune.v
              (Dune.base_project
              @ (Dune.stanzaf "(name %s)" name :: P.dune_project))
          in
          Fmt.str "%a\n" Dune.pp dune
      | `Workspace ->
          let dune =
            match P.dune_workspace with
            | None -> Dune.base_workspace
            | Some f -> f ~build_dir info
          in
          Fmt.str "%a\n" Dune.pp dune
      | `Dist ->
          let install =
            Key.eval (Info.context info) (Engine.install info jobs)
          in
          Fmt.str "%a\n" Dune.pp
            (Install.dune
               ~build_dir:Fpath.(v ".." // build_dir)
               ~context_name:(P.context_name info) install)
    in
    Filegen.write file contents

  let clean (args : _ Cli.clean_args) =
    let* () = Action.rmdir (mirage_dir args) in
    Action.rmdir artifacts_dir

  let generate_makefile ~build_dir ~depext ~extra_repo name =
    let file = Fpath.(v "Makefile") in
    let contents =
      Fmt.to_to_string Makefile.pp
        (Makefile.v ~build_dir ~depext ~name:P.name ?extra_repo name)
    in
    Filegen.write file contents

  let configure ({ args; depext; extra_repo; _ } : _ Cli.configure_args) =
    let { Config.init; info; device_graph; _ } = args.Cli.context in
    (* Get application name *)
    let build_dir = build_dir args in
    let name = P.name_of_target info in
    let* () = generate_makefile ~build_dir ~depext ~extra_repo name in
    let* _ = Action.mkdir (mirage_dir args) in
    let* () =
      Action.with_dir (mirage_dir args) (fun () ->
          (* OPAM files *)
          let* () = generate_opam `Switch ~name args () in
          let* () = generate_opam `Monorepo ~name args () in
          (* Generate application specific-files *)
          Log.info (fun m -> m "in dir %a" (Cli.pp_args (fun _ _ -> ())) args);
          configure_main info init device_graph)
    in
    let* () =
      Action.with_dir build_dir (fun () ->
          let* () = generate_dune `Build args () in
          Filegen.write Fpath.(v "dune") "(include dune.build)")
    in
    (* dune-workspace: defines compilation contexts *)
    let* () = generate_dune `Workspace args () in
    (* dune-project *)
    let* () = generate_dune `Project args () in
    (* Get install spec *)
    let* _ = Action.mkdir artifacts_dir in
    Action.with_dir artifacts_dir (generate_dune `Dist args)

  let ok () = Action.ok ()

  let exit () = Action.error ""

  let with_output args =
    match args.Cli.output with
    | None -> args
    | Some o ->
        let r = args.Cli.context in
        let info = Info.with_output r.Config.info o in
        { args with context = { r with info } }

  let pp_info (f : ('a, Format.formatter, unit) format -> 'a) level args =
    let verbose = Logs.level () >= level in
    f "@[<v>%a@]" (Info.pp verbose) args.Cli.context.Config.info

  let handle_parse_args_result = function
    | `Error _ -> exit ()
    | `Version | `Help -> ok ()
    | `Ok action -> (
        match action with
        | Cli.Help _ -> ok ()
        | Cli.Configure t ->
            let t = { t with args = with_output t.args } in
            Log.info (fun m -> pp_info m (Some Logs.Debug) t.args);
            configure t
        | Cli.Build t ->
            let t = with_output t in
            Log.info (fun m -> pp_info m (Some Logs.Debug) t);
            build t
        | Cli.Query t ->
            let t = { t with args = with_output t.args } in
            Log.info (fun m -> pp_info m (Some Logs.Debug) t.args);
            query t;
            ok ()
        | Cli.Describe t ->
            let t = { t with args = with_output t.args } in
            pp_info Fmt.(pf stdout) (Some Logs.Info) t.args;
            describe t
        | Cli.Clean t ->
            let t = with_output t in
            Log.info (fun m -> pp_info m (Some Logs.Debug) t);
            clean t)

  let action_run args a =
    if not args.Cli.dry_run then Action.run a
    else
      let exec cmd =
        match Bos.Cmd.to_list cmd with
        | [ "opam"; "config"; "var"; "prefix" ] -> Some ("$prefix", "")
        | _ -> Action.default_exec cmd
      in
      let env = Action.env ~files:(`Passtrough (Fpath.v ".")) ~exec () in
      let dom = Action.dry_run ~env a in
      List.iter
        (fun line ->
          Fmt.epr "%a %s\n%!" Fmt.(styled (`Fg `Cyan) string) "*" line)
        dom.logs;
      dom.result

  let read_context args =
    match args.Cli.context_file with
    | None -> Action.ok Context_cache.empty
    | Some file ->
        let* is_file = Action.is_file file in
        if is_file then Context_cache.read file
        else Action.errorf "cannot find file `%a'" Fpath.pp file

  let run_configure_with_argv argv args config =
    (*   whether to fully evaluate the graph *)
    let full_eval = Cli.peek_full_eval argv in

    let* cache = read_context args in
    let base_context =
      (* Consider only the non-required keys. *)
      let non_required_term =
        let if_keys = Config.keys config in
        Key.context ~stage:`Configure ~with_required:false if_keys
      in
      let context =
        match Cmdliner.Term.eval_peek_opts ~argv non_required_term with
        | _, `Ok context -> context
        | _ -> Key.empty_context
      in
      match Context_cache.peek cache non_required_term with
      | None -> context
      | Some default -> Key.merge_context ~default context
    in
    let output = Cli.peek_output argv in

    (* 3. Parse the command-line and handle the result. *)
    let configure =
      eval_cached ~with_required:true ~full:true ~output ~cache base_context
        config
    in

    let describe =
      let full =
        match full_eval with
        | None -> not (Context_cache.is_empty cache)
        | Some b -> b
      in
      eval_cached ~with_required:false ~full ~output ~cache base_context config
    in

    let build =
      eval_cached ~with_required:false ~full:true ~output ~cache base_context
        config
    in
    let clean = build in
    let query = build in
    let help = build in

    handle_parse_args_result
      (Cli.eval ~name:P.name ~version:P.version ~configure ~query ~describe
         ~build ~clean ~help ~mname:P.name argv)

  let register ?packages ?keys ?(init = default_init) ?(src = `Auto) name jobs =
    (* 1. Pre-parse the arguments set the log level, config file
       and root directory. *)
    let argv = Sys.argv in
    (* TODO: do not are parse the command-line twice *)
    let args = Cli.peek_args ~with_setup:true ~mname:P.name argv in
    let run () =
      let build_cmd = get_build_cmd args in
      let main_dev = P.create (init @ jobs) in
      let c = Config.v ?keys ?packages ~init ~build_cmd ~src name main_dev in
      run_configure_with_argv argv args c
    in
    run () |> action_run args |> exit_err args
end
