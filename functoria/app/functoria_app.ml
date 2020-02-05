(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
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

open Rresult
open Astring
open Functoria
include Functoria_misc
module Graph = Functoria_graph
module Key = Functoria_key
module Cli = Functoria_cli
module Engine = Functoria_engine

let src = Logs.Src.create "functoria" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

let wrap f err = match f () with Ok b -> b | Error _ -> R.error_msg err

let with_output f k =
  wrap (Bos.OS.File.with_oc f k)
    ("couldn't open output channel " ^ Fpath.to_string f)

let with_current f k err =
  wrap (Bos.OS.Dir.with_current f k) ("failed to change directory for " ^ err)

module Config = struct
  type t = {
    name : string;
    build_dir : Fpath.t;
    packages : package list Key.value;
    keys : Key.Set.t;
    init : job impl list;
    jobs : Graph.t;
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

  let make ?(keys = []) ?(packages = []) ?(init = []) name build_dir main_dev =
    let name = Name.ocamlify name in
    let jobs = Graph.create main_dev in
    let packages = Key.pure @@ packages in
    let keys = Key.Set.(union (of_list keys) (get_if_context jobs)) in
    { packages; keys; name; build_dir; init; jobs }

  let eval ~partial context { name = n; build_dir; packages; keys; jobs; init }
      =
    let e = Graph.eval ~partial ~context jobs in
    let packages = Key.(pure List.append $ packages $ Engine.packages e) in
    let keys = Key.Set.elements (Key.Set.union keys @@ Engine.all_keys e) in
    Key.(
      pure (fun packages _ context ->
          ((init, e), Info.create ~packages ~keys ~context ~name:n ~build_dir))
      $ packages
      $ of_deps (Set.of_list keys))

  (* Extract all the keys directly. Useful to pre-resolve the keys
     provided by the specialized DSL. *)
  let extract_keys impl = Engine.all_keys @@ Graph.create impl

  let keys t = t.keys

  let gen_pp pp fmt jobs = pp fmt @@ Graph.simplify jobs

  let pp = gen_pp Graph.pp

  let pp_dot = gen_pp Graph.pp_dot
end

(** Cached configuration in [.mirage.config]. Currently, we cache Sys.argv
    directly *)
module Cache : sig
  open Cmdliner

  val save : argv:string array -> Fpath.t -> (unit, [> Rresult.R.msg ]) result

  val clean : Fpath.t -> (unit, [> Rresult.R.msg ]) result

  val get_context :
    Fpath.t ->
    context Term.t ->
    [> `Error of bool * string | `Ok of context option ]

  val get_output : Fpath.t -> [> `Error of bool * string | `Ok of string option ]

  val require :
    [< `Error of bool * string | `Ok of context option ] -> context Term.ret

  val merge :
    cache:[< `Error of bool * string | `Ok of context option ] ->
    context ->
    context

  val present : [< `Error of bool * string | `Ok of context option ] -> bool
end = struct
  let filename root = Fpath.((root / ".mirage") + "config")

  let save ~argv root =
    let file = filename root in
    Log.info (fun m -> m "Preserving arguments in %a" Fpath.pp file);
    let args = List.tl (Array.to_list argv) in
    (* Only keep args *)
    let args = List.map String.Ascii.escape args in
    let args = String.concat ~sep:"\n" args in
    Bos.OS.File.write file args

  let clean root = Bos.OS.File.delete (filename root)

  let read root =
    Log.info (fun l -> l "reading cache");
    match Bos.OS.File.read (filename root) with
    | Error _ -> None
    | Ok args ->
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
    match read root with
    | None -> `Ok None
    | Some argv -> (
        match Cmdliner.Term.eval_peek_opts ~argv context_args with
        | _, `Ok c -> `Ok (Some c)
        | _ ->
            let msg =
              "Invalid cached configuration. Please run configure again."
            in
            `Error (false, msg) )

  let get_output root =
    match get_context root Cli.output with
    | `Ok (Some None) -> `Ok None
    | `Ok (Some x) -> `Ok x
    | `Ok None -> `Ok None
    | `Error e -> `Error e

  let require cache : _ Cmdliner.Term.ret =
    match cache with
    | `Ok None ->
        `Error (false, "Configuration is not available. Please run configure.")
    | `Ok (Some x) -> `Ok x
    | `Error err -> `Error err

  let merge ~cache context =
    match cache with
    | `Ok None | `Error _ -> context
    | `Ok (Some default) -> Key.merge_context ~default context

  let present cache =
    match cache with `Ok None | `Error _ -> false | `Ok (Some _) -> true
end

module type S = sig
  val prelude : string

  val name : string

  val packages : package list

  val ignore_dirs : string list

  val version : string

  val create : job impl list -> job impl
end

module type DSL = module type of struct
  include Functoria
end

module Make (P : S) = struct
  type state = { build_dir : Fpath.t option; config_file : Fpath.t }

  let default_init = [ keys sys_argv ]

  let init_global_state argv =
    ignore (Cmdliner.Term.eval_peek_opts ~argv Cli.setup_log);
    let config_file =
      match Cmdliner.Term.eval_peek_opts ~argv Cli.config_file with
      | None, _ -> Fpath.(v "config.ml")
      | Some f, _ -> f
    in
    let build_dir =
      match Cmdliner.Term.eval_peek_opts ~argv Cli.build_dir with
      | Some (Some d), _ ->
          let (_ : bool) = R.get_ok @@ Bos.OS.Dir.create ~path:true d in
          Some d
      | _ -> None
    in
    { config_file; build_dir }

  let get_project_root () = R.get_ok @@ Bos.OS.Dir.current ()

  let relativize ~root p =
    let p = if Fpath.is_abs p then p else Fpath.(get_project_root () // p) in
    match Fpath.relativize ~root p with
    | Some p -> p
    | None -> Fmt.failwith "relativize: root=%a %a" Fpath.pp root Fpath.pp p

  let get_relative_source_dir ~state =
    let dir = Fpath.parent state.config_file in
    let root = get_project_root () in
    relativize ~root dir

  let get_build_dir ~state =
    let dir =
      match state.build_dir with
      | None -> get_relative_source_dir ~state
      | Some p -> p
    in
    let dir =
      if Fpath.is_abs dir then dir else Fpath.(get_project_root () // dir)
    in
    let root = get_project_root () in
    let rel = relativize ~root dir in
    match Fpath.segs rel with
    | ".." :: _ -> failwith "--build-dir should be a sub-directory."
    | _ -> dir

  let auto_generated =
    Fmt.str ";; %s" (Codegen.generated_header ~argv:[| P.name; "config" |] ())

  let can_overwrite file =
    Bos.OS.File.exists file >>= function
    | false -> Ok true
    | true -> (
        if Fpath.basename file = "dune-project" then
          Bos.OS.File.read_lines file >>| fun x ->
          match List.rev x with x :: _ -> x = auto_generated | _ -> false
        else
          Bos.OS.File.read_lines file >>| function
          | x :: _ -> x = auto_generated
          | _ -> false )

  (* STAGE 1 *)

  let generate ~file ~contents =
    can_overwrite file >>= function
    | false -> Ok ()
    | true ->
        Bos.OS.File.delete file >>= fun () -> Bos.OS.File.write file contents

  let list_files dir =
    Bos.OS.Path.matches ~dotfiles:true Fpath.(dir / "$(file)") >>= fun l ->
    List.fold_left
      (fun acc src ->
        acc >>= fun acc ->
        match Fpath.basename src with
        | "_build" | "main.ml" | "key_gen.ml" -> Ok acc
        | s when Filename.extension s = ".exe" -> Ok acc
        | _ -> Ok (src :: acc))
      (Ok []) l

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
      | None -> ""
      | Some root ->
          let root = Fpath.(project_root // root) in
          let src = relativize ~root file in
          let file = Fpath.basename file in
          Fmt.strf "(rule (copy %a %s))\n\n" Fpath.pp src file
    in
    list_files Fpath.(project_root // source_dir) >>= fun files ->
    let copy_rules = List.map copy_rule files in
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
    ( match Bos.OS.File.must_exist config_file with
    | Ok _ -> Ok ()
    | Error _ ->
        R.error_msgf "configuration file %a missing" Fpath.pp config_file )
    >>= fun () ->
    generate_dune_project ~project_root >>= fun () ->
    Bos.OS.Dir.with_current build_dir
      (fun () ->
        generate_dune_config ~state ~project_root ~source_dir () >>= fun () ->
        generate_empty_dune_build () >>= fun () -> generate_dune ())
      ()
    >>= fun result -> result

  (* Compile the configuration files and execute it. *)
  let build_and_execute ~state ?help_ppf ?err_ppf argv =
    let build_dir = get_build_dir ~state in
    let config_file = state.config_file in
    let project_root = get_project_root () in
    let source_dir = get_relative_source_dir ~state in
    generate_configuration_files ~state ~project_root ~source_dir ~build_dir
      ~config_file
    >>= fun () ->
    let args = Bos.Cmd.of_list (List.tl (Array.to_list argv)) in
    let target_dir = relativize ~root:project_root build_dir in
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
    | None, None -> Bos.OS.Cmd.run command
    | _, _ -> (
        let dune_exec_cmd = Bos.OS.Cmd.run_out command in
        let command_result = Bos.OS.Cmd.to_string dune_exec_cmd in
        match (command_result, help_ppf, err_ppf) with
        | Ok output, Some help_ppf, _ ->
            Format.fprintf help_ppf "%s" output;
            Ok ()
        | Error (`Msg err), _, Some err_ppf ->
            Format.fprintf err_ppf "%s" err;
            Ok ()
        | _ -> Ok () )

  let exit_err = function
    | Ok v -> v
    | Error (`Msg m) ->
        R.pp_msg Format.std_formatter (`Msg m);
        print_newline ();
        flush_all ();
        exit 1

  let handle_parse_args_no_config ?help_ppf ?err_ppf error argv =
    let open Cmdliner in
    let base_keys = Config.extract_keys (P.create []) in
    let base_context =
      Key.context base_keys ~with_required:false ~stage:`Configure
    in
    let result =
      Cli.parse_args ?help_ppf ?err_ppf ~name:P.name ~version:P.version
        ~configure:(Term.pure ()) ~query:(Term.pure ()) ~describe:(Term.pure ())
        ~build:(Term.pure ()) ~clean:(Term.pure ()) ~help:base_context argv
    in
    match result with
    | `Ok Cli.Help -> ()
    | `Error _
    | `Ok
        ( Cli.Configure _ | Cli.Query _ | Cli.Describe _ | Cli.Build _
        | Cli.Clean _ ) ->
        exit_err (Error error)
    | `Version | `Help -> ()

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
    match build_and_execute ~state ?help_ppf ?err_ppf argv with
    | Error (`Invalid_config_ml err) -> exit_err (Error (`Msg err))
    | Error (`Msg _ as err) ->
        handle_parse_args_no_config ?help_ppf ?err_ppf err argv
    | Ok () -> ()

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
        match Cache.get_context t.Config.build_dir term with
        | `Ok (Some c) -> `Ok (Key.eval c info c)
        | `Ok None ->
            let c = Key.empty_context in
            `Ok (Key.eval c info c)
        | (`Error _ | `Help _) as err -> err
      in
      Cmdliner.Term.(ret (pure f $ ret @@ pure @@ Cache.require cached_context))

    let eval ~partial ~with_required context t =
      let info = Config.eval ~partial context t in
      let context =
        Key.context ~with_required ~stage:`Configure (Key.deps info)
      in
      let f map = Key.eval map info map in
      Cmdliner.Term.(pure f $ context)
  end

  let set_output config term =
    match Cache.get_output config.Config.build_dir with
    | `Ok (Some o) ->
        let update_output (r, i) = (r, Info.with_output i o) in
        Cmdliner.Term.(app (const update_output) term)
    | _ -> term

  let exit_err = function
    | Ok v -> v
    | Error (`Msg m) ->
        R.pp_msg Format.std_formatter (`Msg m);
        print_newline ();
        flush_all ();
        exit 1

  (* FIXME: describe init *)
  let describe _info ~dotcmd ~dot ~output (_init, job) =
    let f fmt = (if dot then Config.pp_dot else Config.pp) fmt job in
    let with_fmt f =
      match output with
      | None when dot ->
          f Format.str_formatter;
          let data = Format.flush_str_formatter () in
          Bos.OS.File.tmp ~mode:0o644 "graph%s.dot" >>= fun tmp ->
          Bos.OS.File.write tmp data >>= fun () ->
          Bos.OS.Cmd.run Bos.Cmd.(v dotcmd % p tmp)
      | None -> Ok (f Fmt.stdout)
      | Some s ->
          with_output (Fpath.v s) (fun oc () ->
              Ok (f (Format.formatter_of_out_channel oc)))
    in
    with_fmt f

  let with_output i = function None -> i | Some o -> Info.with_output i o

  let configure_main ~argv i (init, jobs) =
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
    Engine.configure i jobs >>| fun () ->
    Engine.connect i ~init jobs;
    Codegen.newline_main ()

  let clean_main i jobs =
    Engine.clean i jobs >>= fun () -> Bos.OS.File.delete Fpath.(v "main.ml")

  let configure ~state ~argv i jobs =
    let source_dir = get_relative_source_dir ~state in
    Log.debug (fun l -> l "source-dir=%a" Fpath.pp source_dir);
    Log.info (fun m -> m "Configuration: %a" Fpath.pp state.config_file);
    Log.info (fun m ->
        m "Output       : %a" Fmt.(option string) (Info.output i));
    Log.info (fun m -> m "Build-dir    : %a" Fpath.pp (Info.build_dir i));
    with_current (Info.build_dir i)
      (fun () -> configure_main ~argv i jobs)
      "configure"

  let query i = function
    | `Libraries ->
        let libs = Functoria_info.libraries i in
        List.iter (Fmt.pr "%s\n") libs;
        Ok ()

  let build ~state i jobs =
    Log.info (fun m -> m "Building: %a" Fpath.pp state.config_file);
    with_current (Info.build_dir i) (fun () -> Engine.build i jobs) "build"

  let clean ~state i (_init, job) =
    Log.info (fun m -> m "Cleaning: %a" Fpath.pp state.config_file);
    let clean_file file =
      can_overwrite file >>= function
      | false -> Ok ()
      | true -> Bos.OS.File.delete file
    in
    clean_file Fpath.(v "dune-project") >>= fun () ->
    Cache.clean (Info.build_dir i) >>= fun () ->
    ( match Sys.getenv "INSIDE_FUNCTORIA_TESTS" with
    | "1" -> Ok ()
    | exception Not_found -> Bos.OS.Dir.delete ~recurse:true Fpath.(v "_build")
    | _ -> Bos.OS.Dir.delete ~recurse:true Fpath.(v "_build") )
    >>= fun () ->
    with_current (Info.build_dir i)
      (fun () ->
        clean_main i job >>= fun () ->
        clean_file Fpath.(v "dune") >>= fun () ->
        clean_file Fpath.(v "dune.config") >>= fun () ->
        clean_file Fpath.(v "dune.build") >>= fun () ->
        Bos.OS.File.delete Fpath.(v ".merlin"))
      "clean"

  let handle_parse_args_result ~state argv = function
    | `Error _ -> exit 1
    | `Ok Cli.Help -> ()
    | `Ok (Cli.Configure { result = jobs, info; output }) ->
        let info = with_output info output in
        Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
        exit_err (configure ~state ~argv info jobs)
    | `Ok (Cli.Build ((_, jobs), info)) ->
        Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
        exit_err (build ~state info jobs)
    | `Ok (Cli.Query { result = _, info; kind }) ->
        Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
        exit_err (query info kind)
    | `Ok (Cli.Describe { result = jobs, info; dotcmd; dot; output }) ->
        Config'.pp_info Fmt.(pf stdout) (Some Logs.Info) info;
        R.error_msg_to_invalid_arg (describe info jobs ~dotcmd ~dot ~output)
    | `Ok (Cli.Clean (jobs, info)) ->
        Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
        exit_err (clean ~state info jobs)
    | `Version | `Help -> ()

  let run_configure_with_argv argv config =
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
    let cached_context = Cache.get_context config.build_dir if_term in

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
      |> set_output config
    and clean =
      Config'.eval_cached ~partial:false cached_context config
      |> set_output config
    and help =
      let context = Cache.merge ~cache:cached_context context in
      let info = Config.eval ~partial:false context config in
      let keys = Key.deps info in
      Key.context ~stage:`Configure ~with_required:false keys
    in

    handle_parse_args_result argv
      (Cli.parse_args ~name:P.name ~version:P.version ~configure ~query
         ~describe ~build ~clean ~help argv)

  let register ?packages ?keys ?(init = default_init) name jobs =
    (* 1. Pre-parse the arguments set the log level, config file
       and root directory. *)
    let state = init_global_state Sys.argv in
    let build_dir = get_build_dir ~state in
    let main_dev = P.create (init @ jobs) in
    let c = Config.make ?keys ?packages ~init name build_dir main_dev in
    run_configure_with_argv ~state Sys.argv c
end
