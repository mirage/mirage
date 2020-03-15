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

open Action.Infix
open Astring
open DSL
module Name = Misc.Name

let src = Logs.Src.create "functoria" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

module Config = struct
  type t = {
    name : string;
    build_cmd : string list;
    build_dir : Fpath.t;
    packages : package list Key.value;
    keys : Key.Set.t;
    init : job impl list;
    jobs : Device_graph.t;
    src : [ `Auto | `None | `Some of string ];
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

  let v ?(keys = []) ?(packages = []) ?(init = []) ~build_dir ~build_cmd ~src
      name main_dev =
    let name = Name.ocamlify name in
    let jobs = Device_graph.create main_dev in
    let packages = Key.pure @@ packages in
    let keys = Key.Set.(union (of_list keys) (get_if_context jobs)) in
    { packages; keys; name; build_dir; init; jobs; build_cmd; src }

  let eval ~partial context
      { name = n; build_dir; build_cmd; packages; keys; jobs; init; src } =
    let e = Device_graph.eval ~partial ~context jobs in
    let packages = Key.(pure List.append $ packages $ Engine.packages e) in
    let keys = Key.Set.elements (Key.Set.union keys @@ Engine.all_keys e) in
    Key.(
      pure (fun packages _ context ->
          ( (init, e),
            Info.v ~packages ~keys ~context ~build_dir ~build_cmd ~src n ))
      $ packages
      $ of_deps (Set.of_list keys))

  (* Extract all the keys directly. Useful to pre-resolve the keys
     provided by the specialized DSL. *)
  let extract_keys impl = Engine.all_keys @@ Device_graph.create impl

  let keys t = t.keys

  let gen_pp pp fmt jobs = pp fmt @@ Device_graph.simplify jobs

  let pp = gen_pp Device_graph.pp

  let pp_dot = gen_pp Device_graph.pp_dot
end

(** Cached configuration in [.mirage.config]. Currently, we cache Sys.argv
    directly *)
module Cache : sig
  open Cmdliner

  val save : argv:string array -> Fpath.t -> unit Action.t

  val clean : Fpath.t -> unit Action.t

  val get_context : Fpath.t -> context Term.t -> context option Action.t

  val get_output : Fpath.t -> string option Action.t

  val require : context option -> context Term.ret

  val merge : cache:context option -> context -> context

  val present : context option -> bool
end = struct
  let filename root = Fpath.(normalize @@ ((root / ".mirage") + "config"))

  let save ~argv root =
    let file = filename root in
    Log.info (fun m -> m "Preserving arguments in %a" Fpath.pp file);
    let args = List.tl (Array.to_list argv) in
    (* Only keep args *)
    let args = List.map String.Ascii.escape args in
    let args = String.concat ~sep:"\n" args in
    Action.write_file file args

  let clean root = Action.rm (filename root)

  let read root =
    Log.info (fun l -> l "reading cache");
    Action.is_file (filename root) >>= function
    | false -> Action.ok None
    | true ->
        Action.read_file (filename root) >|= fun args ->
        let contents = Array.of_list @@ String.cuts ~sep:"\n" args in
        let contents =
          Array.map
            (fun x ->
              match String.Ascii.unescape x with
              | Some s -> s
              | None -> failwith "cannot parse cached context")
            contents
        in
        Some contents

  let get_context root context_args =
    read root >>= function
    | None -> Action.ok None
    | Some argv -> (
        match Cmdliner.Term.eval_peek_opts ~argv context_args with
        | _, `Ok c -> Action.ok (Some c)
        | _ ->
            let msg =
              "Invalid cached configuration. Please run configure again."
            in
            Action.error msg )

  let get_output root =
    get_context root Cli.output >|= function
    | Some None -> None
    | Some x -> x
    | None -> None

  let require cache : _ Cmdliner.Term.ret =
    match cache with
    | None ->
        `Error (false, "Configuration is not available. Please run configure.")
    | Some x -> `Ok x

  let merge ~cache context =
    match cache with
    | None -> context
    | Some default -> Key.merge_context ~default context

  let present cache = match cache with None -> false | Some _ -> true
end

module type S = sig
  val prelude : string

  val name : string

  val packages : package list

  val ignore_dirs : string list

  val version : string

  val create : job impl list -> job impl
end

module Make (P : S) = struct
  type state = {
    build_dir : Fpath.t option;
    config_file : Fpath.t;
    dry_run : bool;
  }

  let default_init = [ Job.keys Argv.sys_argv ]

  let init_global_state argv =
    ignore (Cmdliner.Term.eval_peek_opts ~argv Cli.setup_log);
    let config_file =
      match Cmdliner.Term.eval_peek_opts ~argv Cli.config_file with
      | None, _ -> Fpath.(v "config.ml")
      | Some f, _ -> f
    in
    let build_dir =
      match Cmdliner.Term.eval_peek_opts ~argv Cli.build_dir with
      | Some (Some d), _ -> Some d
      | _ -> None
    in
    let dry_run =
      match Cmdliner.Term.eval_peek_opts ~argv Cli.dry_run with
      | Some v, _ -> v
      | None, _ -> false
    in
    { config_file; build_dir; dry_run }

  let get_project_root () = Action.pwd ()

  let relativize ~root p =
    let p =
      if Fpath.is_abs p then Action.ok p
      else get_project_root () >|= fun root -> Fpath.(root // p)
    in
    p >|= fun p ->
    match Fpath.relativize ~root p with
    | Some p -> p
    | None -> Fmt.failwith "relativize: root=%a %a" Fpath.pp root Fpath.pp p

  let get_relative_source_dir ~state =
    let dir = Fpath.parent state.config_file in
    get_project_root () >>= fun root -> relativize ~root dir

  let get_build_dir ~state =
    let dir =
      match state.build_dir with
      | None -> get_relative_source_dir ~state
      | Some p -> Action.ok p
    in
    dir >>= fun dir ->
    Action.mkdir dir >>= fun _ ->
    get_project_root () >>= fun root ->
    let dir = if Fpath.is_abs dir then dir else Fpath.(root // dir) in
    relativize ~root dir >>= fun rel ->
    match Fpath.segs rel with
    | ".." :: _ -> Action.error "--build-dir should be a sub-directory."
    | _ -> Action.ok dir

  let get_build_cmd ~state =
    let build_dir =
      match state.build_dir with
      | None -> []
      | Some d -> [ "--build-dir"; Fpath.to_string d ]
    in
    P.name
    :: "build"
    :: "--config-file"
    :: Fpath.to_string state.config_file
    :: build_dir

  let auto_generated =
    Fmt.str ";; %s" (Codegen.generated_header ~argv:[| P.name; "config" |] ())

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

  (* STAGE 1 *)

  let generate ~file ~contents =
    can_overwrite file >>= function
    | false -> Action.ok ()
    | true -> Action.rm file >>= fun () -> Action.write_file file contents

  let list_files dir =
    Action.ls dir >|= fun files ->
    List.filter
      (fun src ->
        match Fpath.basename src with
        | "_build" | "main.ml" | "key_gen.ml" -> false
        | s when Filename.extension s = ".exe" -> false
        | _ -> true)
      files

  (* Generate a `dune.config` file in the build directory. *)
  let generate_dune_config ~state ~project_root ~source_dir () =
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
    let copy_rule file =
      match state.build_dir with
      | None -> Action.ok ""
      | Some root ->
          let root = Fpath.(project_root // root) in
          relativize ~root file >|= fun src ->
          let file = Fpath.basename file in
          Fmt.strf "(rule (copy %a %s))\n\n" Fpath.pp src file
    in
    list_files Fpath.(project_root // source_dir) >>= fun files ->
    Action.List.map ~f:copy_rule files >>= fun copy_rules ->
    let config_file = Fpath.(basename (rem_ext state.config_file)) in
    let contents =
      Fmt.strf
        {|%s

%a(executable
  (name config)
  (modules %s)
  (libraries %s))
|}
        auto_generated
        Fmt.(list ~sep:(unit "") string)
        copy_rules config_file pkgs
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
  let generate_dune_project ~project_root =
    let file = Fpath.(project_root / "dune-project") in
    let contents = Fmt.strf "(lang dune 1.1)\n%s\n" auto_generated in
    generate ~file ~contents

  (* Generate the configuration files in the the build directory *)
  let generate_configuration_files ~state ~project_root ~source_dir ~build_dir
      ~config_file =
    Log.info (fun m -> m "Compiling: %a" Fpath.pp config_file);
    Log.info (fun m -> m "Project root: %a" Fpath.pp project_root);
    Log.info (fun m -> m "Build dir: %a" Fpath.pp build_dir);
    (Action.is_file config_file >>= function
     | true -> Action.ok ()
     | false ->
         Action.errorf "configuration file %a missing" Fpath.pp config_file)
    >>= fun () ->
    generate_dune_project ~project_root >>= fun () ->
    Action.with_dir build_dir (fun () ->
        generate_dune_config ~state ~project_root ~source_dir () >>= fun () ->
        generate_empty_dune_build () >>= fun () -> generate_dune ())

  (* Compile the configuration files and execute it. *)
  let build_and_execute ~state ?help_ppf ?err_ppf argv =
    let config_file = state.config_file in
    get_build_dir ~state >>= fun build_dir ->
    get_project_root () >>= fun project_root ->
    get_relative_source_dir ~state >>= fun source_dir ->
    generate_configuration_files ~state ~project_root ~source_dir ~build_dir
      ~config_file
    >>= fun () ->
    let args = Bos.Cmd.of_list (List.tl (Array.to_list argv)) in
    relativize ~root:project_root build_dir >>= fun target_dir ->
    let command =
      Bos.Cmd.(
        v "dune"
        % "exec"
        % "--root"
        % p project_root
        % "--"
        % p Fpath.(target_dir / "config.exe")
        %% args)
    in
    match (help_ppf, err_ppf) with
    | None, None -> Action.run_cmd command
    | _, _ -> (
        Action.run_cmd_out command >|= fun command_result ->
        match (command_result, help_ppf, err_ppf) with
        | output, Some help_ppf, _ -> Format.fprintf help_ppf "%s" output
        | _ -> () )

  let exit_err = function
    | Ok v -> v
    | Error (`Msg m) ->
        flush_all ();
        if m <> "" then Fmt.epr "%a\n%!" Fmt.(styled (`Fg `Red) string) m;
        exit 1

  let handle_parse_args_no_config ?help_ppf ?err_ppf (`Msg error) argv =
    let open Cmdliner in
    let base_keys = Config.extract_keys (P.create []) in
    let base_context =
      Key.context base_keys ~with_required:false ~stage:`Configure
    in
    let niet = Term.pure (Action.ok ()) in
    let result =
      Cli.parse_args ?help_ppf ?err_ppf ~name:P.name ~version:P.version
        ~configure:niet ~query:niet ~describe:niet ~build:niet ~clean:niet
        ~help:base_context argv
    in
    let ok = Action.ok () in
    let error = Action.error error in
    match result with
    | `Error _ -> error
    | `Version | `Help -> ok
    | `Ok Cli.Help -> ok
    | `Ok
        ( Cli.Configure _ | Cli.Query _ | Cli.Describe _ | Cli.Build _
        | Cli.Clean _ ) ->
        error

  let run_with_argv ?help_ppf ?err_ppf argv =
    (* 1. Pre-parse the arguments set the log level, config file
       and root directory. *)
    let state = init_global_state argv in

    (* 2. Build the config from the config file. *)
    (* There are three possible outcomes:
         1. the config file is found and built successfully
         2. no config file is specified
         3. an attempt is made to access the base keys at this point.
            when they weren't loaded *)
    build_and_execute ~state ?help_ppf ?err_ppf argv |> Action.run |> function
    | Ok () -> ()
    | Error (`Msg _ as err) ->
        handle_parse_args_no_config ?help_ppf ?err_ppf err argv
        |> Action.run
        |> exit_err

  let run () = run_with_argv Sys.argv

  (* STAGE 2 *)

  let src = Logs.Src.create (P.name ^ "-configure") ~doc:"functoria generated"

  module Log = (val Logs.src_log src : Logs.LOG)

  module Config' = struct
    let pp_info (f : ('a, Format.formatter, unit) format -> 'a) level info =
      let verbose = Logs.level () >= level in
      f "@[<v>%a@]" (Info.pp verbose) info

    let eval_cached ~partial cached_context t =
      let f c =
        let info = Config.eval ~partial c t in
        let keys = Key.deps info in
        let term = Key.context ~stage:`Configure ~with_required:false keys in
        Cache.get_context t.Config.build_dir term >|= function
        | Some c -> Key.eval c info c
        | None ->
            let c = Key.empty_context in
            Key.eval c info c
      in
      Cmdliner.Term.(pure f $ ret @@ pure @@ Cache.require cached_context)

    let eval ~partial ~with_required context t =
      let info = Config.eval ~partial context t in
      let context =
        Key.context ~with_required ~stage:`Configure (Key.deps info)
      in
      let f map = Key.eval map info map in
      Cmdliner.Term.(pure f $ context)
  end

  let set_term_output config (term : 'a Action.t Cmdliner.Term.t) =
    let f term =
      Cache.get_output config.Config.build_dir >>= function
      | Some o -> term >|= fun (r, i) -> (r, Info.with_output i o)
      | _ -> term
    in
    Cmdliner.Term.(pure f $ term)

  (* FIXME: describe init *)
  let describe _info ~dotcmd ~dot ~output (_init, job) =
    let f fmt = (if dot then Config.pp_dot else Config.pp) fmt job in
    let with_fmt f =
      match output with
      | None when dot ->
          f Format.str_formatter;
          let data = Format.flush_str_formatter () in
          Action.tmp_file ~mode:0o644 "graph%s.dot" >>= fun tmp ->
          Action.write_file tmp data >>= fun () ->
          Action.run_cmd Bos.Cmd.(v dotcmd % p tmp)
      | None -> Action.ok (f Fmt.stdout)
      | Some s -> Action.with_output ~path:(Fpath.v s) ~purpose:"dot file" f
    in
    with_fmt f

  let with_output i = function None -> i | Some o -> Info.with_output i o

  let configure_main ~argv i (init, jobs) : unit Action.t =
    let main = match Info.output i with None -> "main" | Some f -> f in
    let file = main ^ ".ml" in
    Log.info (fun m -> m "Generating: %s" file);
    Codegen.set_main_ml file;
    Codegen.append_main "(* %s *)" (Codegen.generated_header ());
    Codegen.newline_main ();
    Codegen.append_main "%a" Fmt.text P.prelude;
    Codegen.newline_main ();
    Codegen.append_main "let _ = Printexc.record_backtrace true";
    Codegen.newline_main ();
    Cache.save ~argv (Info.build_dir i) >>= fun () ->
    Engine.configure i jobs >|= fun () ->
    Engine.connect i ~init jobs;
    Codegen.newline_main ()

  let clean_main i jobs =
    Engine.clean i jobs >>= fun () -> Action.rm Fpath.(v "main.ml")

  let configure_opam i =
    let file = Info.name i ^ ".opam" in
    let opam = Info.opam i in
    Log.info (fun m -> m "Generating: %s" file);
    Action.write_file Fpath.(v file) (Fmt.str "%a%!" Opam.pp opam)

  let clean_opam i =
    let file = Info.name i ^ ".opam" in
    Action.rm Fpath.(v file)

  let eval_install i (_, e) = Key.eval (Info.context i) (Engine.install i e)

  let configure_install i jobs =
    let file = Info.name i ^ ".install" in
    let install = eval_install i jobs in
    Log.info (fun m -> m "Generating: %s" file);
    Action.write_file Fpath.(v file) (Fmt.str "%a%!" Install.pp install)

  let clean_install i =
    let file = Info.name i ^ ".install" in
    Action.rm Fpath.(v file)

  let configure ~state ~argv i jobs =
    get_relative_source_dir ~state >>= fun source_dir ->
    Log.debug (fun l -> l "source-dir=%a" Fpath.pp source_dir);
    Log.info (fun m -> m "Configuration: %a" Fpath.pp state.config_file);
    Log.info (fun m ->
        m "Output       : %a" Fmt.(option string) (Info.output i));
    Log.info (fun m -> m "Build-dir    : %a" Fpath.pp (Info.build_dir i));
    (* Generate .opam and .install at the project root *)
    configure_opam i >>= fun () ->
    configure_install i jobs >>= fun () ->
    (* Generate main.ml, *_gen.ml in the build dir *)
    Action.with_dir (Info.build_dir i) (fun () -> configure_main ~argv i jobs)

  let query i (t : Cli.query_kind) jobs =
    match t with
    | `Packages ->
        let pkgs = Info.packages i in
        List.iter (Fmt.pr "%a\n" (Package.pp ~surround:"\"")) pkgs
    | `Opam ->
        let opam = Info.opam i in
        Fmt.pr "%a%!" Opam.pp opam
    | `Install ->
        let install = eval_install i jobs in
        Fmt.pr "%a%!" Install.pp install

  let build ~state i jobs =
    Log.info (fun m -> m "Building: %a" Fpath.pp state.config_file);
    Action.with_dir (Info.build_dir i) (fun () -> Engine.build i jobs)

  let clean ~state i (_init, job) =
    Log.info (fun m -> m "Cleaning: %a" Fpath.pp state.config_file);
    let clean_file file =
      can_overwrite file >>= function
      | false -> Action.ok ()
      | true -> Action.rm file
    in
    clean_file Fpath.(v "dune-project") >>= fun () ->
    Cache.clean (Info.build_dir i) >>= fun () ->
    ( match Sys.getenv "INSIDE_FUNCTORIA_TESTS" with
    | "1" -> Action.ok ()
    | exception Not_found -> Action.rmdir Fpath.(v "_build")
    | _ -> Action.rmdir Fpath.(v "_build") )
    >>= fun () ->
    clean_opam i >>= fun () ->
    clean_install i >>= fun () ->
    Action.with_dir (Info.build_dir i) (fun () ->
        clean_main i job >>= fun () ->
        clean_file Fpath.(v "dune") >>= fun () ->
        clean_file Fpath.(v "dune.config") >>= fun () ->
        clean_file Fpath.(v "dune.build") >>= fun () ->
        Action.rm Fpath.(v ".merlin"))

  let ok () = Action.ok ()

  let exit () = Action.error ""

  let handle_parse_args_result ~state argv = function
    | `Error _ -> exit ()
    | `Version | `Help -> ok ()
    | `Ok action -> (
        match action with
        | Cli.Help -> ok ()
        | Cli.Configure { result = jobs, info; output } ->
            let info = with_output info output in
            Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
            configure ~state ~argv info jobs >>= ok
        | Cli.Build ((_, jobs), info) ->
            Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
            build ~state info jobs >>= ok
        | Cli.Query { result = jobs, info; kind } ->
            Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
            query info kind jobs;
            ok ()
        | Cli.Describe { result = jobs, info; dotcmd; dot; output } ->
            Config'.pp_info Fmt.(pf stdout) (Some Logs.Info) info;
            describe info jobs ~dotcmd ~dot ~output >>= ok
        | Cli.Clean (jobs, info) ->
            Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
            clean ~state info jobs >>= ok )

  let action_run ~state a =
    if not state.dry_run then Action.run a
    else
      let vfs = Action.vfs ~files:(`Passtrough (Fpath.v ".")) () in
      let r, _, lines = Action.dry_run ~vfs a in
      List.iter
        (fun line ->
          Fmt.epr "%a %s\n%!" Fmt.(styled (`Fg `Cyan) string) "*" line)
        lines;
      let () =
        match r with
        | Ok _ -> Fmt.epr "%a\n%!" Fmt.(styled (`Fg `Green) string) "[OK]"
        | Error _ -> Fmt.epr "%a\n%!" Fmt.(styled (`Fg `Red) string) "[ERROR]"
      in
      r

  let run_term ~state term =
    Cmdliner.Term.(term_result ~usage:false (pure (action_run ~state) $ term))

  let run_configure_with_argv argv config ~state =
    (*   whether to fully evaluate the graph *)
    let full_eval = Cli.read_full_eval argv in
    (* Consider only the 'if' keys. *)
    let if_term =
      let if_keys = Config.keys config in
      Key.context ~stage:`Configure ~with_required:false if_keys
    in

    let context =
      match Cmdliner.Term.eval_peek_opts ~argv if_term with
      | _, `Ok context -> context
      | _ -> Key.empty_context
    in

    (* this is a trim-down version of the cached context, with only
        the values corresponding to 'if' keys. This is useful to
        start reducing the config into something consistent. *)
    Cache.get_context config.build_dir if_term >>= fun cached_context ->
    (* 3. Parse the command-line and handle the result. *)
    let configure =
      Config'.eval ~with_required:true ~partial:false context config
    and describe =
      let context = Cache.merge ~cache:cached_context context in
      let partial =
        match full_eval with
        | Some true -> false
        | Some false -> true
        | None -> not (Cache.present cached_context)
      in
      Config'.eval ~with_required:false ~partial context config
    and query = Config'.eval ~with_required:true ~partial:false context config
    and build =
      Config'.eval_cached ~partial:false cached_context config
      |> set_term_output config
      |> run_term ~state
    and clean =
      Config'.eval_cached ~partial:false cached_context config
      |> set_term_output config
      |> run_term ~state
    and help =
      let context = Cache.merge ~cache:cached_context context in
      let info = Config.eval ~partial:false context config in
      let keys = Key.deps info in
      Key.context ~stage:`Configure ~with_required:false keys
    in
    handle_parse_args_result argv ~state
      (Cli.parse_args ~name:P.name ~version:P.version ~configure ~query
         ~describe ~build ~clean ~help argv)

  let register ?packages ?keys ?(init = default_init) ?(src = `Auto) name jobs =
    (* 1. Pre-parse the arguments set the log level, config file
       and root directory. *)
    let state = init_global_state Sys.argv in
    let run () =
      get_build_dir ~state >>= fun build_dir ->
      let build_cmd = get_build_cmd ~state in
      let main_dev = P.create (init @ jobs) in
      let c =
        Config.v ?keys ?packages ~init ~build_dir ~build_cmd ~src name main_dev
      in
      run_configure_with_argv ~state Sys.argv c
    in
    run () |> action_run ~state |> exit_err
end
