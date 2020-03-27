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

  let v ?(keys = []) ?(packages = []) ?(init = []) ~build_cmd ~src name main_dev
      =
    let name = Name.ocamlify name in
    let jobs = Device_graph.create main_dev in
    let packages = Key.pure @@ packages in
    let keys = Key.Set.(union (of_list keys) (get_if_context jobs)) in
    { packages; keys; name; init; jobs; build_cmd; src }

  let eval ~partial context
      { name = n; build_cmd; packages; keys; jobs; init; src } =
    let e = Device_graph.eval ~partial ~context jobs in
    let packages = Key.(pure List.append $ packages $ Engine.packages e) in
    let keys = Key.Set.elements (Key.Set.union keys @@ Engine.all_keys e) in
    Key.(
      pure (fun packages _ context ->
          ((init, e), Info.v ~packages ~keys ~context ~build_cmd ~src n))
      $ packages
      $ of_deps (Set.of_list keys))

  let keys t = t.keys

  let gen_pp pp fmt jobs = pp fmt @@ Device_graph.simplify jobs

  let pp = gen_pp Device_graph.pp

  let pp_dot = gen_pp Device_graph.pp_dot
end

module type S = sig
  val prelude : string

  val name : string

  val version : string

  val create : job impl list -> job impl
end

module Make (P : S) = struct
  let cache root = Fpath.(normalize @@ (root / ("." ^ P.name ^ ".config")))

  let default_init = [ Job.keys Argv.sys_argv ]

  let build_dir args = Fpath.parent args.Cli.config_file

  let get_build_cmd args =
    [ P.name; "build"; "--config-file"; Fpath.to_string args.Cli.config_file ]

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

  let exit_err args = function
    | Ok v -> v
    | Error (`Msg m) ->
        flush_all ();
        if m <> "" then Fmt.epr "%a\n%!" Fmt.(styled (`Fg `Red) string) m;
        if not args.Cli.dry_run then exit 1 else Fmt.epr "(exit 1)"

  (* STAGE 2 *)

  let src = Logs.Src.create (P.name ^ "-configure") ~doc:"functoria generated"

  module Log = (val Logs.src_log src : Logs.LOG)

  module Config' = struct
    let eval_cached ~partial cache cached_context t =
      let f c _ =
        let info = Config.eval ~partial c t in
        let keys = Key.deps info in
        let context = Key.context ~stage:`Configure ~with_required:false keys in
        Context_cache.eval cache context >|= fun c -> Key.eval c info c
      in
      Cmdliner.Term.(
        pure f $ pure cached_context $ ret (pure (Context_cache.require cache)))

    let eval ~partial ~with_required context t =
      let info = Config.eval ~partial context t in
      let context =
        Key.context ~with_required ~stage:`Configure (Key.deps info)
      in
      let f map = Key.eval map info map in
      Cmdliner.Term.(pure f $ context)
  end

  (* FIXME: describe init *)
  let describe (t : _ Cli.describe_args) =
    let (_, jobs), _ = t.Cli.args.context in
    let f fmt = (if t.dot then Config.pp_dot else Config.pp) fmt jobs in
    let with_fmt f =
      match t.args.output with
      | None when t.dot ->
          f Format.str_formatter;
          let data = Format.flush_str_formatter () in
          Action.tmp_file ~mode:0o644 "graph%s.dot" >>= fun tmp ->
          Action.write_file tmp data >>= fun () ->
          Action.run_cmd Bos.Cmd.(v t.dotcmd % p tmp)
      | None -> Action.ok (f Fmt.stdout)
      | Some s -> Action.with_output ~path:(Fpath.v s) ~purpose:"dot file" f
    in
    with_fmt f

  let configure_main ~argv i (init, jobs) : unit Action.t =
    let main = Info.main i in
    let purpose = Fmt.strf "configure: create %a" Fpath.pp main in
    Log.info (fun m -> m "Generating: %a" Fpath.pp main);
    Action.with_output ~path:main ~append:false ~purpose (fun ppf ->
        Fmt.pf ppf "(* %s *)@.@." (Codegen.generated_header ());
        Fmt.pf ppf "%a@.@." Fmt.text P.prelude;
        Fmt.pf ppf "let _ = Printexc.record_backtrace true@.@.")
    >>= fun () ->
    Context_cache.write (cache (Fpath.v ".")) argv >>= fun () ->
    Engine.configure i jobs >>= fun () -> Engine.connect i ~init jobs

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

  let configure ~argv args =
    let jobs, i = args.Cli.context in
    Log.info (fun m -> m "Configuration: %a" Fpath.pp args.Cli.config_file);
    let () =
      match Info.output i with
      | None -> ()
      | Some o -> Log.info (fun m -> m "Output       : %a" Fmt.(string) o)
    in
    (* Generate .opam and .install at the project root *)
    configure_opam i >>= fun () ->
    configure_install i jobs >>= fun () ->
    (* Generate main.ml, *_gen.ml in the build dir *)
    Action.with_dir (build_dir args) (fun () -> configure_main ~argv i jobs)

  let build args =
    let (_, jobs), i = args.Cli.context in
    Log.info (fun m -> m "Building: %a" Fpath.pp args.Cli.config_file);
    Action.with_dir (build_dir args) (fun () -> Engine.build i jobs)

  let query ~argv ({ args; kind } : _ Cli.query_args) =
    let jobs, i = args.Cli.context in
    match kind with
    | `Name -> Fmt.pr "%s\n%!" (Info.name i)
    | `Packages ->
        let pkgs = Info.packages i in
        List.iter (Fmt.pr "%a\n%!" (Package.pp ~surround:"\"")) pkgs
    | `Opam ->
        let opam = Info.opam i in
        Fmt.pr "%a%!" Opam.pp opam
    | `Install ->
        let install = eval_install i jobs in
        Fmt.pr "%a%!" Install.pp install
    | `Files stage ->
        let actions =
          match stage with
          | `Configure -> configure ~argv args
          | `Build -> build args
        in
        let files = Fpath.Set.elements (Action.generated_files actions) in
        Fmt.pr "%a\n%!" Fmt.(list ~sep:(unit " ") Fpath.pp) files

  let clean args =
    let (_, jobs), i = args.Cli.context in
    Log.info (fun m -> m "Cleaning: %a" Fpath.pp args.Cli.config_file);
    let clean_file file =
      can_overwrite file >>= function
      | false -> Action.ok ()
      | true -> Action.rm file
    in
    clean_file Fpath.(v "dune-project") >>= fun () ->
    Action.rm (cache (build_dir args)) >>= fun () ->
    ( match Sys.getenv "INSIDE_FUNCTORIA_TESTS" with
    | "1" -> Action.ok ()
    | exception Not_found -> Action.rmdir Fpath.(v "_build")
    | _ -> Action.rmdir Fpath.(v "_build") )
    >>= fun () ->
    clean_opam i >>= fun () ->
    clean_install i >>= fun () ->
    Action.with_dir (build_dir args) (fun () ->
        clean_main i jobs >>= fun () ->
        clean_file Fpath.(v "dune") >>= fun () ->
        clean_file Fpath.(v "dune.config") >>= fun () ->
        clean_file Fpath.(v "dune.build") >>= fun () ->
        Action.rm Fpath.(v ".merlin"))

  let ok () = Action.ok ()

  let exit () = Action.error ""

  let with_output args =
    match args.Cli.output with
    | None -> args
    | Some o ->
        let jobs, i = args.Cli.context in
        let i = Info.with_output i o in
        { args with context = (jobs, i) }

  let pp_info (f : ('a, Format.formatter, unit) format -> 'a) level args =
    let verbose = Logs.level () >= level in
    let _, i = args.Cli.context in
    f "@[<v>%a@]" (Info.pp verbose) i

  let handle_parse_args_result argv = function
    | `Error _ -> exit ()
    | `Version | `Help -> ok ()
    | `Ok action -> (
        match action with
        | Cli.Help _ -> ok ()
        | Cli.Configure t ->
            let t = with_output t in
            Log.info (fun m -> pp_info m (Some Logs.Debug) t);
            configure ~argv t
        | Cli.Build t ->
            let t = with_output t in
            Log.info (fun m -> pp_info m (Some Logs.Debug) t);
            build t
        | Cli.Query t ->
            let t = { t with args = with_output t.args } in
            Log.info (fun m -> pp_info m (Some Logs.Debug) t.args);
            query ~argv t;
            ok ()
        | Cli.Describe t ->
            let t = { t with args = with_output t.args } in
            pp_info Fmt.(pf stdout) (Some Logs.Info) t.args;
            describe t
        | Cli.Clean t ->
            let t = with_output t in
            Log.info (fun m -> pp_info m (Some Logs.Debug) t);
            clean t )

  let action_run args a =
    if not args.Cli.dry_run then Action.run a
    else
      let env = Action.env ~files:(`Passtrough (Fpath.v ".")) () in
      let r, _, lines = Action.dry_run ~env a in
      List.iter
        (fun line ->
          Fmt.epr "%a %s\n%!" Fmt.(styled (`Fg `Cyan) string) "*" line)
        lines;
      r

  let run_term argv term =
    Cmdliner.Term.(term_result ~usage:false (pure (action_run argv) $ term))

  let set_term_output cache (term : 'a Action.t Cmdliner.Term.t) =
    let f term =
      Context_cache.eval_output cache >>= function
      | Some o -> term >|= fun (r, i) -> (r, Info.with_output i o)
      | _ -> term
    in
    Cmdliner.Term.(pure f $ term)

  let run_configure_with_argv argv args config =
    (*   whether to fully evaluate the graph *)
    let full_eval = Cli.peek_full_eval argv in
    (* Consider only the non-required keys. *)
    let non_required_term =
      let if_keys = Config.keys config in
      Key.context ~stage:`Configure ~with_required:false if_keys
    in

    let base_context =
      match Cmdliner.Term.eval_peek_opts ~argv non_required_term with
      | _, `Ok context -> context
      | _ -> Key.empty_context
    in

    (* this is a trim-down version of the cached context, with only
        the values corresponding to 'if' keys. This is useful to
        start reducing the config into something consistent. *)
    Context_cache.read (cache (build_dir args)) >>= fun cache ->
    Context_cache.eval cache non_required_term >>= fun cached_context ->
    (* 3. Parse the command-line and handle the result. *)
    let configure =
      Config'.eval ~with_required:true ~partial:false base_context config
    in
    let query = configure in

    let describe =
      let context = Key.merge_context ~default:cached_context base_context in
      let partial =
        match full_eval with
        | Some true -> false
        | Some false -> true
        | None -> cache = None
      in
      Config'.eval ~with_required:false ~partial context config
    in

    let build =
      Config'.eval_cached ~partial:false cache cached_context config
      |> set_term_output cache
      |> run_term args
    in
    let clean = build in

    let help =
      let context = Key.merge_context ~default:cached_context base_context in
      Config'.eval ~with_required:false ~partial:false context config
    in

    handle_parse_args_result argv
      (Cli.eval ~name:P.name ~version:P.version ~configure ~query ~describe
         ~build ~clean ~help argv)

  let register ?packages ?keys ?(init = default_init) ?(src = `Auto) name jobs =
    (* 1. Pre-parse the arguments set the log level, config file
       and root directory. *)
    let argv = Sys.argv in
    (* TODO: do not are parse the command-line twice *)
    let args = Cli.peek_args argv in
    let run () =
      let build_cmd = get_build_cmd args in
      let main_dev = P.create (init @ jobs) in
      let c = Config.v ?keys ?packages ~init ~build_cmd ~src name main_dev in
      run_configure_with_argv argv args c
    in
    run () |> action_run args |> exit_err args
end
