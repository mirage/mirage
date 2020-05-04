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
  module Filegen = Filegen.Make (P)

  let default_init = [ Job.keys Argv.sys_argv ]

  let build_dir args = Fpath.parent args.Cli.config_file

  let get_build_cmd args =
    [ P.name; "build"; "--config-file"; Fpath.to_string args.Cli.config_file ]

  let exit_err args = function
    | Ok v -> v
    | Error (`Msg m) ->
        flush_all ();
        if m <> "" then Fmt.epr "%a\n%!" Fmt.(styled (`Fg `Red) string) m;
        if not args.Cli.dry_run then exit 1 else Fmt.epr "(exit 1)"

  (* STAGE 2 *)

  let src = Logs.Src.create (P.name ^ "-configure") ~doc:"functoria generated"

  module Log = (val Logs.src_log src : Logs.LOG)

  let eval_cached ~partial ~with_required ~output ~cache context t =
    let info = Config.eval ~partial context t in
    let keys = Key.deps info in
    let output =
      match (output, Context_cache.peek_output cache) with
      | Some _, _ -> output
      | _, cache -> cache
    in
    let context = Key.context ~stage:`Configure ~with_required keys in
    let context = Context_cache.merge cache context in
    let f context =
      let r, i = Key.eval context info context in
      match output with None -> (r, i) | Some o -> (r, Info.with_output i o)
    in
    Cmdliner.Term.(pure f $ context)

  (* FIXME: describe init *)
  let describe (t : _ Cli.describe_args) =
    let (_, jobs), _ = t.Cli.args.context in
    let f fmt =
      Fmt.pf fmt "%a\n%!" (if t.dot then Config.pp_dot else Config.pp) jobs
    in
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

  let configure_main i (init, jobs) =
    let main = Info.main i in
    let purpose = Fmt.strf "configure: create %a" Fpath.pp main in
    Log.info (fun m -> m "Generating: %a (main file)" Fpath.pp main);
    Action.with_output ~path:main ~append:false ~purpose (fun ppf ->
        Fmt.pf ppf "%a@.@.let _ = Printexc.record_backtrace true@.@." Fmt.text
          P.prelude)
    >>= fun () ->
    Engine.configure i jobs >>= fun () -> Engine.connect i ~init jobs

  let clean_main i jobs =
    Engine.clean i jobs >>= fun () -> Action.rm (Info.main i)

  let configure args =
    let jobs, i = args.Cli.context in
    Log.info (fun m -> m "Configuration: %a" Fpath.pp args.Cli.config_file);
    let () =
      match Info.output i with
      | None -> ()
      | Some o -> Log.info (fun m -> m "Output       : %a" Fmt.(string) o)
    in
    Action.with_dir (build_dir args) (fun () -> configure_main i jobs)

  let files i jobs s =
    let main = Info.main i in
    let files = Engine.files i jobs s in
    let files = if s = `Configure then main :: files else files in
    Fpath.Set.(elements (of_list files))

  let build args =
    let (_, jobs), i = args.Cli.context in
    Log.info (fun m -> m "Building: %a" Fpath.pp args.Cli.config_file);
    Action.with_dir (build_dir args) (fun () -> Engine.build i jobs)

  let query ({ args; kind; depext } : _ Cli.query_args) =
    let jobs, i = args.Cli.context in
    match kind with
    | `Name -> Fmt.pr "%s\n%!" (Info.name i)
    | `Packages ->
        let pkgs = Info.packages i in
        List.iter (Fmt.pr "%a\n%!" (Package.pp ~surround:"\"")) pkgs
    | `Opam ->
        let opam = Info.opam i in
        Fmt.pr "%a\n%!" Opam.pp opam
    | `Install ->
        let install = Key.eval (Info.context i) (Engine.install i (snd jobs)) in
        Fmt.pr "%a\n%!" Install.pp install
    | `Files stage ->
        let files = files i (snd jobs) stage in
        Fmt.pr "%a\n%!" Fmt.(list ~sep:(unit " ") Fpath.pp) files
    | `Makefile ->
        let file = Makefile.v ~depext (Info.name i) in
        Fmt.pr "%a\n%!" Makefile.pp file

  let clean args =
    let (_, jobs), i = args.Cli.context in
    Log.info (fun m -> m "Cleaning: %a" Fpath.pp args.Cli.config_file);
    Action.with_dir (build_dir args) (fun () ->
        clean_main i jobs >>= fun () ->
        Filegen.rm Fpath.(v "dune") >>= fun () ->
        Filegen.rm Fpath.(v "dune.config") >>= fun () ->
        Filegen.rm Fpath.(v "dune.build") >>= fun () ->
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

  let handle_parse_args_result = function
    | `Error _ -> exit ()
    | `Version | `Help -> ok ()
    | `Ok action -> (
        match action with
        | Cli.Help _ -> ok ()
        | Cli.Configure t ->
            let t = { t with args = with_output t.args } in
            Log.info (fun m -> pp_info m (Some Logs.Debug) t.args);
            configure t.args
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

  let read_context args =
    match args.Cli.context_file with
    | None -> Action.ok Context_cache.empty
    | Some file -> (
        Action.is_file file >>= function
        | false -> Action.errorf "cannot find file `%a'" Fpath.pp file
        | true -> Context_cache.read file >|= fun t -> t )

  let run_configure_with_argv argv args config =
    (*   whether to fully evaluate the graph *)
    let full_eval = Cli.peek_full_eval argv in

    read_context args >>= fun cache ->
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
      eval_cached ~with_required:true ~partial:false ~output ~cache base_context
        config
    in

    let describe =
      let partial =
        match full_eval with
        | Some true -> false
        | Some false -> true
        | None -> Context_cache.is_empty cache
      in
      eval_cached ~with_required:false ~partial ~output ~cache base_context
        config
    in

    let build =
      eval_cached ~with_required:false ~partial:false ~output ~cache
        base_context config
    in
    let clean = build in
    let query = build in
    let help = build in

    handle_parse_args_result
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
