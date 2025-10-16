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
    config_file : Fpath.t;
    name : string;
    project_name : string;
    configure_cmd : string;
    pre_build_cmd : Fpath.t option -> string;
    lock_location : Fpath.t option -> string -> string;
    build_cmd : Fpath.t option -> string;
    packages : package list Key.value;
    local_libs : string list;
    if_keys : Key.Set.t;
    runtime_args : Runtime_arg.Set.t;
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
    let all_keys = Engine.keys jobs in
    let skeys = Engine.if_keys jobs in
    let f k s = if true then s else Key.Set.add k s in
    Key.Set.fold f all_keys skeys

  let v ?(config_file = Fpath.v "config.ml") ?(init = []) ~configure_cmd
      ~pre_build_cmd ~lock_location ~build_cmd ~src ~project_name name jobs =
    let local_libs = Impl.local_libs jobs in
    let jobs = Impl.abstract jobs in
    let if_keys = get_if_context jobs in
    let runtime_args = Runtime_arg.Set.empty in
    {
      config_file;
      if_keys;
      runtime_args;
      name;
      project_name;
      init;
      configure_cmd;
      pre_build_cmd;
      lock_location;
      build_cmd;
      packages = Key.pure [];
      local_libs;
      jobs;
      src;
    }

  let eval ~full context
      {
        config_file;
        name = n;
        project_name;
        configure_cmd;
        pre_build_cmd;
        lock_location;
        build_cmd;
        packages;
        local_libs;
        if_keys;
        runtime_args;
        jobs;
        init;
        src;
      } =
    let jobs = Impl.simplify ~full ~context jobs in
    let device_graph = Impl.eval ~context jobs in
    let packages = Key.(pure List.append $ packages $ Engine.packages jobs) in
    let all_keys = Engine.keys jobs in
    let all_runtime_args = Engine.runtime_args jobs in
    let runtime_args =
      Runtime_arg.Set.(elements (union runtime_args all_runtime_args))
    in
    let keys = Key.Set.(elements (union if_keys all_keys)) in
    let mk packages _ context =
      let info =
        Info.v ~config_file ~packages ~local_libs ~keys ~runtime_args ~context
          ~configure_cmd ~pre_build_cmd ~lock_location ~build_cmd ~src
          ~project_name n
      in
      { init; jobs; info; device_graph }
    in
    Key.(pure mk $ packages $ of_deps (Set.of_list keys))

  let if_keys t = t.if_keys
  let pp_dot = Impl.pp_dot
end

module type S = sig
  val prelude : Info.t -> string
  val packages : Package.t list
  val name : string
  val version : string
  val create : job impl list -> job impl
  val name_of_target : Info.t -> string
  val target_filename : Info.t -> string
  val dune_project : Dune.stanza list
  val dune_workspace : (?build_dir:Fpath.t -> info -> Dune.t) option
  val context_name : Info.t -> string
end

module Make (P : S) = struct
  module Filegen = Filegen.Make (P)

  let default_init = [ Job.runtime_args Argv.sys_argv ]
  let build_dir args = Fpath.parent args.Cli.config_file
  let config_file args = args.Cli.config_file
  let mirage_dir args = Fpath.(build_dir args / P.name)
  let artifacts_dir args = Fpath.(build_dir args / "dist")

  let exit_err args = function
    | Ok v -> v
    | Error (`Msg m) ->
        flush_all ();
        if m <> "" then Fmt.epr "%a\n%!" Fmt.(styled (`Fg `Red) string) m;
        if not args.Cli.dry_run then exit 1 else Fmt.epr "(exit 1)"

  let get_cmds _ =
    let command_line_arguments =
      Sys.argv
      |> Array.to_list
      |> List.tl
      |> List.filter (fun arg ->
             arg <> "configure" && arg <> "query" && arg <> "opam")
      |> String.concat ~sep:" "
    in
    let opts =
      if command_line_arguments = "" then None else Some command_line_arguments
    in
    ( Fmt.str {|%s configure%a --no-extra-repo|} P.name
        Fmt.(option ~none:(any "") (any " " ++ string))
        opts,
      (fun sub ->
        Fmt.str {|make %a"lock" "depext-lockfile" "pull"|}
          Fmt.(option ~none:(any "") (any "\"-C" ++ Fpath.pp ++ any "\" "))
          sub),
      (fun sub unikernel ->
        Fmt.str {|%amirage/%s.opam.locked|}
          Fmt.(option ~none:(any "") Fpath.pp)
          sub unikernel),
      fun sub ->
        Fmt.str {|make %a"build"|}
          Fmt.(option ~none:(any "") (any "\"-C" ++ Fpath.pp ++ any "\" "))
          sub )

  (* STAGE 2 *)

  let src = Logs.Src.create (P.name ^ "-configure") ~doc:"functoria generated"

  module Log = (val Logs.src_log src : Logs.LOG)

  let eval_cached ~full ~output ~cache context t =
    let info = Config.eval ~full context t in
    let keys = Key.deps info in
    let output =
      match (output, Context_cache.peek_output cache) with
      | Some _, _ -> output
      | _, cache -> cache
    in
    let context = Key.context keys in
    let context = Context_cache.merge cache context in
    let f context =
      let config = Key.eval context info context in
      match output with
      | None -> config
      | Some o -> { config with info = Info.with_output config.info o }
    in
    Cmdliner.Term.(const f $ context)

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
      | Some "-" -> Action.ok (f Fmt.stdout)
      | Some s -> Action.with_output ~path:(Fpath.v s) ~purpose:"dot file" f
    in
    with_fmt f

  let configure_main i init jobs =
    let main = Info.main i in
    let purpose = Fmt.str "configure: create %a" Fpath.pp main in
    Log.info (fun m -> m "Generating: %a (main file)" Fpath.pp main);
    let* () =
      Action.with_output ~path:main ~append:false ~purpose (fun ppf ->
          Fmt.pf ppf "%a@.@." Fmt.text (P.prelude i))
    in
    let* () = Engine.configure i jobs in
    Engine.connect i ~init jobs

  let files i jobs =
    let main = Info.main i in
    let files = Engine.files i jobs in
    let files = Fpath.Set.add main files in
    Fpath.Set.(elements files)

  let opam_contents ~opam_name ~extra_repo args =
    let { Config.info; jobs; _ } = args.Cli.context in
    let install = Key.eval (Info.context info) (Engine.install info jobs) in
    let name = Misc.Name.Opam.to_string opam_name in
    let opam = Info.opam ~install ~extra_repo ~opam_name:name info in
    Fmt.str "%a" Opam.pp opam

  let generate_opam ~opam_name ~extra_repo args =
    let contents = opam_contents ~opam_name ~extra_repo args in
    let name = Misc.Name.Opam.to_string opam_name in
    let file = Fpath.(v (name ^ ".opam")) in
    Log.info (fun m ->
        m "Generating: %a (%a)" Fpath.pp file Cli.pp_query_kind `Opam);
    Filegen.write file contents

  let copy_files files =
    List.map
      (fun f ->
        match Fpath.split_ext f with
        | _, (".ml" | ".mli") -> Dune.stanzaf "(copy_files# %a)" Fpath.pp f
        | _ -> Dune.stanzaf "(copy_files %a)" Fpath.pp f)
      files

  let dune_contents alias args =
    let { Config.info; jobs; _ } = args.Cli.context in
    let name = P.name_of_target info in
    let build_dir = build_dir args in
    match alias with
    | `Build ->
        let files = files info jobs in
        let files = List.map (fun p -> Fpath.(v "." / P.name // p)) files in
        let dune = Dune.v (copy_files files @ Engine.dune info jobs) in
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
        let install = Key.eval (Info.context info) (Engine.install info jobs) in
        Fmt.str "%a\n" Dune.pp
          (Install.dune ~context_name_for_bin:(P.context_name info)
             ~context_name_for_etc:"default" install)
    | `Config ->
        let cwd = Bos.OS.Dir.current () |> Result.get_ok in
        let config_ml_file = Fpath.(cwd // args.Cli.config_file) in
        let dune = Dune.base ~config_ml_file ~packages:P.packages in
        Fmt.str "%a\n" Dune.pp dune

  let generate_dune alias args =
    let contents = dune_contents alias args in
    let file =
      match alias with
      | `Dist -> Fpath.(v "dune")
      | `Build -> Fpath.(v "dune.build")
      | `Config -> Fpath.(v "dune.config")
      | `Workspace -> Fpath.(v "dune-workspace")
      | `Project -> Fpath.(v "dune-project")
    in
    Log.info (fun m ->
        m "Generating: %a (%a)" Fpath.pp file Cli.pp_query_kind
          (`Dune alias :> Cli.query_kind));
    Filegen.write file contents

  let makefile_contents ~build_dir ~depext ~extra_repo ~public_name opam_name =
    Fmt.to_to_string Makefile.pp
      (Makefile.v ~build_dir ~depext ~builder_name:P.name ~public_name
         ~extra_repo opam_name)

  let generate_makefile ~build_dir ~depext ~extra_repo ~public_name opam_name =
    let contents =
      makefile_contents ~build_dir ~depext ~extra_repo ~public_name opam_name
    in
    let file = Fpath.(v "Makefile") in
    Filegen.write file contents

  let public_name info =
    let default = P.target_filename info in
    Option.value ~default (Info.output info)

  let query ({ args; kind; depext; extra_repo } : _ Cli.query_args) =
    let { Config.jobs; info; _ } = args.Cli.context in
    let name = P.name_of_target info in
    let build_dir = Fpath.parent args.config_file in
    let public_name = public_name info in
    match kind with
    | `Name -> Fmt.pr "%s\n%!" (Info.name info)
    | `Packages ->
        let pkgs = Info.packages info in
        List.iter (Fmt.pr "%a\n%!" (Package.pp ~surround:"\"")) pkgs
    | `Opam ->
        let opam_name = Misc.Name.opamify name in
        let contents = opam_contents ~opam_name ~extra_repo args in
        Fmt.pr "%s\n%!" contents
    | `Files ->
        let files = files info jobs in
        Fmt.pr "%a\n%!" Fmt.(list ~sep:(any " ") Fpath.pp) files
    | `Makefile ->
        let opam_name = Misc.Name.opamify name in
        let contents =
          makefile_contents ~build_dir ~depext ~extra_repo ~public_name
            opam_name
        in
        Fmt.pr "%s\n%!" contents
    | `Dune alias -> Fmt.pr "%s%!" (dune_contents alias args)

  (* Configuration step. *)

  let clean (args : _ Cli.clean_args) =
    let* () = Action.rmdir (mirage_dir args) in
    Action.rmdir (artifacts_dir args)

  let configure ({ args; depext; extra_repo; _ } : _ Cli.configure_args) =
    let { Config.init; info; device_graph; _ } = args.Cli.context in
    (* Get application name *)
    let build_dir = build_dir args in
    let name = P.name_of_target info in
    let opam_name = Misc.Name.opamify name in
    let public_name = public_name info in
    let* () =
      generate_makefile ~build_dir ~depext ~extra_repo ~public_name opam_name
    in
    let* _ = Action.mkdir (mirage_dir args) in
    let* () =
      Action.with_dir (mirage_dir args) (fun () ->
          (* OPAM file *)
          let* () = generate_opam ~opam_name ~extra_repo args in
          (* Generate application specific-files *)
          Log.info (fun m -> m "in dir %a" (Cli.pp_args (fun _ _ -> ())) args);
          configure_main info init device_graph)
    in
    let* () =
      Action.with_dir build_dir (fun () ->
          let* () = generate_dune `Build args in
          Filegen.write Fpath.(v "dune") "(include dune.build)\n")
    in
    (* dune-workspace: defines compilation contexts *)
    let* () = generate_dune `Workspace args in
    (* dune-project *)
    let* () = generate_dune `Project args in
    (* Get install spec *)
    let* _ = Action.mkdir (artifacts_dir args) in
    Action.with_dir (artifacts_dir args) (fun () -> generate_dune `Dist args)

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

  let run_with_argv argv args config =
    (*   whether to fully evaluate the graph *)
    let full_eval = Cli.peek_full_eval argv in

    let* cache = read_context args in
    let base_context =
      (* Consider only the non-required keys. *)
      let non_required_term =
        let if_keys = Config.if_keys config in
        Key.context if_keys
      in
      let context =
        match Cmdliner.Cmd.eval_peek_opts ~argv non_required_term with
        | _, Ok (`Ok context) -> context
        | _ -> Context.empty
      in
      match Context_cache.peek cache non_required_term with
      | None -> context
      | Some default -> Context.merge ~default context
    in
    let output = Cli.peek_output argv in

    (* 3. Parse the command-line and handle the result. *)
    let configure = eval_cached ~full:true ~output ~cache base_context config in

    let describe =
      let full =
        match full_eval with
        | None -> not (Context_cache.is_empty cache)
        | Some b -> b
      in
      eval_cached ~full ~output ~cache base_context config
    in

    let clean = eval_cached ~full:true ~output ~cache base_context config in
    let query = clean in
    let help = clean in

    handle_parse_args_result
      (Cli.eval ~name:P.name ~version:P.version ~configure ~query ~describe
         ~clean ~help ~mname:P.name argv)

  let register ?(init = default_init) ?(src = `Auto) name jobs =
    (* 1. Pre-parse the arguments set the log level, config file
       and root directory. *)
    let argv = Sys.argv in
    (* TODO: do not are parse the command-line twice *)
    let args =
      (* tool.ml made sure that global arguments are correctly parsed before
         running config.exe*)
      Cli.peek_args ~with_setup:true ~mname:P.name argv |> Option.get
    in
    let config_file = config_file args in
    let run () =
      let configure_cmd, pre_build_cmd, lock_location, build_cmd =
        get_cmds args
      in
      let main_dev = P.create (init @ jobs) in
      let c =
        Config.v ~config_file ~init ~configure_cmd ~pre_build_cmd ~lock_location
          ~build_cmd ~src ~project_name:P.name name main_dev
      in
      run_with_argv argv args c
    in
    run () |> action_run args |> exit_err args
end
