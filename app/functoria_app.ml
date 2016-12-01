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

let (/) = Filename.concat

(* Noop, the job that does nothing. *)
let noop = impl @@ object
    inherit base_configurable
    method ty = job
    method name = "noop"
    method module_name = "Pervasives"
  end

(* Default argv *)
type argv = ARGV
let argv = Type ARGV

let sys_argv = impl @@ object
    inherit base_configurable
    method ty = argv
    method name = "argv"
    method module_name = "Sys"
    method !connect _info _m _ = "return Sys.argv"
  end

let src = Logs.Src.create "functoria" ~doc:"functoria library"
module Log = (val Logs.src_log src : Logs.LOG)

let wrap f err =
  match f () with
  | Ok b -> b
  | Error _ -> R.error_msg err

let with_output f k =
  wrap
    (Bos.OS.File.with_oc f k)
    ("couldn't open output channel " ^ Fpath.to_string f)

let with_current f k err =
  wrap
    (Bos.OS.Dir.with_current f k)
    ("failed to change directory for " ^ err)

(* Keys *)

module Keys = struct

  let configure i =
    let file = String.Ascii.lowercase Key.module_name ^ ".ml" in
    Log.info (fun m -> m "Generating: %s" file);
    with_output Fpath.(v (Info.root i) / file)
      (fun oc () ->
         let fmt = Format.formatter_of_out_channel oc in
         Codegen.append fmt "(* %s *)" (Codegen.generated_header ());
         Codegen.newline fmt;
         let keys = Key.Set.of_list @@ Info.keys i in
         let pp_var k = Key.serialize (Info.context i) k in
         Fmt.pf fmt "@[<v>%a@]@." (Fmt.iter Key.Set.iter pp_var) keys;
         let runvars = Key.Set.elements (Key.filter_stage `Run keys) in
         let pp_runvar ppf v = Fmt.pf ppf "%s_t" (Key.ocaml_name v) in
         let pp_names ppf v = Fmt.pf ppf "%S" (Key.name v) in
         Codegen.append fmt "let runtime_keys = List.combine %a %a"
           Fmt.Dump.(list pp_runvar) runvars Fmt.Dump.(list pp_names) runvars;
         Codegen.newline fmt;
         R.ok ())

  let clean i =
    let file = String.Ascii.lowercase Key.module_name ^ ".ml" in
    Bos.OS.Path.delete Fpath.(v (Info.root i) / file)

  let name = "key"

end

let keys (argv: argv impl) = impl @@ object
    inherit base_configurable
    method ty = job
    method name = Keys.name
    method module_name = Key.module_name
    method !configure = Keys.configure
    method !clean = Keys.clean
    method !packages = Key.pure [package "functoria-runtime"]
    method !deps = [ abstract argv ]
    method !connect info modname = function
      | [ argv ] ->
        Fmt.strf
          "return (Functoria_runtime.with_argv (List.map fst %s.runtime_keys) %S %s)"
          modname (Info.name info) argv
      | _ -> failwith "The keys connect should receive exactly one argument."
  end

(* Module emiting a file containing all the build information. *)

type info = Info
let info = Type Info

(* hannes is pretty sure the following pp needs adjustments, but unclear to me
   what exactly to do here? i.e. who reads the formatted stuff in again? *)
let pp_libraries fmt l =
  Fmt.pf fmt "[@ %a]"
    Fmt.(iter ~sep:(unit ";@ ") List.iter @@ fmt "%S") l

let pp_packages fmt l =
  Fmt.pf fmt "[@ %a]"
    Fmt.(iter ~sep:(unit ";@ ") List.iter @@
         (fun fmt x -> pf fmt "%S, \"%%{%s:version}%%\"" x x)
        ) l

let pp_dump_info module_name fmt i =
  Fmt.pf fmt
    "%s.{@ name = %S;@ \
     @[<v 2>packages = %a@]@ ;@ @[<v 2>libraries = %a@]@ }"
    module_name (Info.name i)
    pp_packages (Info.package_names i)
    pp_libraries (Info.libraries i)

let app_info ?(type_modname="Functoria_info")  ?(gen_modname="Info_gen") () =
  impl @@ object
    inherit base_configurable
    method ty = info
    method name = "info"
    val gen_file = String.Ascii.lowercase gen_modname  ^ ".ml"
    method module_name = gen_modname
    method !packages = Key.pure [package "functoria-runtime"]
    method !connect _ modname _ = Fmt.strf "return %s.info" modname

    method !clean i =
      let file = Fpath.(v (Info.root i) / gen_file) in
      Bos.OS.Path.delete file >>= fun () ->
      Bos.OS.Path.delete Fpath.(file + "in")

    method !configure i =
      let file = Fpath.(v (Info.root i) / gen_file) in
      Log.info (fun m -> m "Generating: %s" gen_file);
      Bos.OS.File.writef Fpath.(file + "in")
        "@[<v 2>let info = %a@]" (pp_dump_info type_modname) i

    method !build _i =
      Bos.OS.Cmd.run Bos.Cmd.(v "opam" % "config" % "subst" % gen_file)
  end

module Engine = struct

  let if_context =
    let open Graph in
    Graph.collect (module Key.Set) @@ function
    | If cond      -> Key.deps cond
    | App | Impl _ -> Key.Set.empty

  let keys =
    let open Graph in
    Graph.collect (module Key.Set) @@ function
    | Impl c  -> Key.Set.of_list c#keys
    | If cond -> Key.deps cond
    | App     -> Key.Set.empty

  module M = struct
    type t = package list Key.value
    let union x y = Key.(pure List.append $ x $ y)
    let empty = Key.pure []
  end

  let packages =
    let open Graph in
    Graph.collect (module M) @@ function
    | Impl c     -> c#packages
    | If _ | App -> M.empty

  (* Return a unique variable name holding the state of the given
     module construction. *)
  let name c id =
    let prefix = Name.ocamlify c#name in
    Name.create (Fmt.strf "%s%i" prefix id) ~prefix

  (* [module_expresion tbl c args] returns the module expression of
     the functor [c] applies to [args]. *)
  let module_expression tbl fmt (c, args) =
    Fmt.pf fmt "%s%a"
      c#module_name
      Fmt.(list (parens @@ of_to_string @@ Graph.Tbl.find tbl))
      args

  (* [module_name tbl c args] return the module name of the result of
     the functor application. If [args = []], it returns
     [c#module_name]. *)
  let module_name c id args =
    let base = c#module_name in
    if args = [] then base
    else
      let prefix = match String.cut ~sep:"." base with
        | Some (l, _) -> l
        | None -> base
      in
      let prefix = Name.ocamlify prefix in
      Name.create (Fmt.strf "%s%i" prefix id) ~prefix

  (* FIXME: Can we do better than lookup by name? *)
  let find_device info g impl =
    let ctx = Info.context info in
    let rec name: type a . a impl -> string = fun impl ->
      match explode impl with
      | `Impl c              -> c#name
      | `App (Abstract x, _) -> name x
      | `If (b, x, y)        -> if Key.eval ctx b then name x else name y
    in
    let name = name impl in
    let open Graph in
    let p = function
      | Impl c     -> c#name = name
      | App | If _ -> false
    in
    match Graph.find_all g p with
    | []  -> invalid_arg "Functoria.find_device: no device"
    | [x] -> x
    | _   -> invalid_arg "Functoria.find_device: too many devices."

  let build info (_init, job) =
    let f v = match Graph.explode job v with
      | `App _ | `If _ -> R.ok ()
      | `Impl (c, _, _) -> c#build info
    in
    let f v res = res >>= fun () -> f v in
    Graph.fold f job @@ R.ok ()

  let configure info (_init, job) =
    let tbl = Graph.Tbl.create 17 in
    let f v = match Graph.explode job v with
      | `App _ | `If _ -> assert false
      | `Impl (c, `Args args, `Deps _) ->
        let modname = module_name c (Graph.hash v) args in
        Graph.Tbl.add tbl v modname;
        c#configure info >>| fun () ->
        if args = [] then ()
        else begin
          Codegen.append_main
            "@[<2>module %s =@ %a@]"
            modname
            (module_expression tbl) (c,args);
          Codegen.newline_main ();
        end
    in
    let f v res = res >>= fun () -> f v in
    Graph.fold f job @@ R.ok () >>| fun () ->
    tbl

  let meta_init fmt (connect_name, result_name) =
    Fmt.pf fmt "let _%s =@[@ Lazy.force %s @]in@ " result_name connect_name

  let emit_connect fmt (iname, names, connect_string) =
    (* We avoid potential collision between double application
       by prefixing with "_". This also avoid warnings. *)
    let rnames = List.map (fun x -> "_"^x) names in
    let bind ppf name =
      Fmt.pf ppf "_%s >>= fun %s ->@ " name name
    in
    Fmt.pf fmt
      "@[<v 2>let %s = lazy (@ \
       %a\
       %a\
       %s@ )@]@."
      iname
      Fmt.(list ~sep:nop meta_init) (List.combine names rnames)
      Fmt.(list ~sep:nop bind) rnames
      (connect_string rnames)

  let emit_run init main =
    (* "exit 1" is ok in this code, since cmdliner will print help. *)
    let force ppf name =
      Fmt.pf ppf "Lazy.force %s >>= fun _ ->@ " name
    in
    Codegen.append_main
      "@[<v 2>\
       let () =@ \
       let t =@ @[<v 2>%aLazy.force %s@]@ \
       in run t@]"
      Fmt.(list ~sep:nop force) init main

  let connect modtbl info (init, job) =
    let tbl = Graph.Tbl.create 17 in
    let f v = match Graph.explode job v with
      | `App _ | `If _ -> assert false
      | `Impl (c, `Args args, `Deps deps) ->
        let ident = name c (Graph.hash v) in
        let modname = Graph.Tbl.find modtbl v in
        Graph.Tbl.add tbl v ident;
        let names = List.map (Graph.Tbl.find tbl) (args @ deps) in
        Codegen.append_main "%a"
          emit_connect (ident, names, c#connect info modname)
    in
    Graph.fold (fun v () -> f v) job ();
    let main_name = Graph.Tbl.find tbl @@ Graph.find_root job in
    let init_names =
      List.map (fun name -> Graph.Tbl.find tbl @@ find_device info job name) init
    in
    emit_run init_names main_name;
    ()

  let configure_and_connect info g =
    configure info g >>| fun modtbl ->
    connect modtbl info g

  let clean i g =
    let f v = match Graph.explode g v with
      | `Impl (c,_,_) -> c#clean i
      | _ -> R.ok ()
    in
    let f v res = res >>= fun () -> f v in
    Graph.fold f g @@ R.ok ()

end

module Config = struct

  type t = {
    name     : string;
    root     : string;
    packages: package list Key.value;
    keys    : Key.Set.t;
    init    : job impl list;
    jobs    : Graph.t;
  }

  (* In practice, we get all the keys associated to [if] cases, and
     all the keys that have a setter to them. *)
  let get_if_context jobs =
    let all_keys = Engine.keys jobs in
    let skeys = Engine.if_context jobs in
    let f k s =
      if Key.Set.is_empty @@ Key.Set.inter (Key.aliases k) skeys
      then s
      else Key.Set.add k s
    in
    Key.Set.fold f all_keys skeys

  let make ?(keys=[]) ?(packages=[]) ?(init=[]) name root
      main_dev =
    let jobs = Graph.create main_dev in
    let packages = Key.pure @@ packages in
    let keys = Key.Set.(union (of_list keys) (get_if_context jobs)) in
    { packages; keys; name; root; init; jobs }

  let eval ~partial context
      { name = n; root; packages; keys; jobs; init }
    =
    let e = Graph.eval ~partial ~context jobs in
    let packages = Key.(pure List.append $ packages $ Engine.packages e) in
    let keys = Key.Set.elements (Key.Set.union keys @@ Engine.keys e) in
    Key.(pure (fun packages _ context ->
        ((init, e),
         Info.create
           ~packages
           ~keys ~context ~name:n ~root))
         $ packages
         $ of_deps (Set.of_list keys))

  (* Extract all the keys directly. Useful to pre-resolve the keys
     provided by the specialized DSL. *)
  let extract_keys impl =
    Engine.keys @@ Graph.create impl

  let name t = t.name
  let keys t = t.keys

  let gen_pp pp fmt jobs =
    pp fmt @@ Graph.simplify jobs

  let pp = gen_pp Graph.pp
  let pp_dot = gen_pp Graph.pp_dot

end

(** Cached configuration in [.mirage.config].
    Currently, we cache Sys.argv directly
*)
module Cache : sig
  open Cmdliner
  val save : string -> (unit, [> Rresult.R.msg ]) result
  val clean : string -> (unit, [> Rresult.R.msg ]) result
  val get_context : string -> context Term.t ->
    [> `Error of bool * string | `Ok of context option ]
  val require :
    [< `Error of bool * string | `Ok of context option ] -> context Term.ret
  val merge :
    cache:[< `Error of bool * string | `Ok of context option ] ->
    context -> context
  val present :
    [< `Error of bool * string | `Ok of context option ] -> bool
end = struct
  let filename root =
    Fpath.(v root / ".mirage" + "config")

  let save root =
    let file = filename root in
    Log.info (fun m -> m "Preserving arguments");
    let args = String.concat ~sep:";" Array.(to_list Sys.argv) in
    Bos.OS.File.write file args

  let clean root =
    Bos.OS.File.delete (filename root)

  let read root =
    match Bos.OS.File.read (filename root) with
    | Ok args ->
      Some (Array.of_list @@ String.cuts ~empty:false ~sep:";" args)
    | Error _ -> None

  let get_context root context_args =
    match read root with
    | None -> `Ok None
    | Some argv ->
      match Cmdliner.Term.eval_peek_opts ~argv context_args with
      | _, `Ok c -> `Ok (Some c)
      | _ ->
        let msg =
          "Invalid cached configuration. Please run configure again."
        in
        `Error (false, msg)

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

  let present cache = match cache with
    | `Ok None | `Error _ -> false
    | `Ok (Some _) -> true
end

module type S = sig
  val prelude: string
  val name: string
  val version: string
  val create: job impl list -> job impl
end

module type DSL = module type of struct include Functoria end

module Make (P: S) = struct

  let src = Logs.Src.create P.name ~doc:"functoria generated"
  module Log = (val Logs.src_log src : Logs.LOG)

  let configuration = ref None
  let config_file = ref None

  let set_config_file f =
    config_file := Some f

  let get_config_file () =
    match !config_file with
    | None -> Sys.getcwd () / "config.ml"
    | Some f -> f

  let get_root () = Filename.dirname @@ get_config_file ()

  let register ?(packages=[]) ?keys ?(init=[]) name jobs =
    let keys = match keys with None -> [] | Some x -> x in
    let root = get_root () in
    let main_dev = P.create (init @ jobs) in
    let c = Config.make ~keys ~packages ~init name root main_dev in
    configuration := Some c

  let registered () =
    match !configuration with
    | None   ->
      Log.err (fun m -> m "No configuration was registered.") ;
      Error (`Msg "no configuration file was registered")
    | Some t -> Ok t

  let configure_main i jobs =
    Log.info (fun m -> m "Generating: main.ml");
    Codegen.set_main_ml "main.ml";
    Codegen.append_main "(* %s *)" (Codegen.generated_header ());
    Codegen.newline_main ();
    Codegen.append_main "%a" Fmt.text  P.prelude;
    Codegen.newline_main ();
    Codegen.append_main "let _ = Printexc.record_backtrace true";
    Codegen.newline_main ();
    Cache.save (Info.root i) >>= fun () ->
    Engine.configure_and_connect i jobs >>| fun () ->
    Codegen.newline_main ()

  let clean_main i jobs =
    Engine.clean i jobs >>= fun () ->
    Bos.OS.File.delete Fpath.(v "main.ml")

  let configure i jobs =
    Log.info (fun m -> m "Using configuration: %s" (get_config_file ()));
    Log.info (fun m -> m "opam: %a" (Info.opam ?name:None) i);
    Log.info (fun m -> m "within: %s" (Info.root i));
    with_current
      (Fpath.v (Info.root i))
      (fun () -> configure_main i jobs)
      "configure"

  let build i jobs =
    Log.info (fun m -> m "Building: %s" (get_config_file ()));
    with_current
      (Fpath.v (Info.root i))
      (fun () -> Engine.build i jobs)
      "build"

  let clean i (_init, job) =
    Log.info (fun m -> m "Cleaning: %s" (get_config_file ()));
    let root = Info.root i in
    with_current
      (Fpath.v root)
      (fun () ->
         clean_main i job >>= fun () ->
         Bos.OS.Dir.delete ~recurse:true (Fpath.v "_build") >>= fun () ->
         Cache.clean root >>= fun () ->
         Bos.OS.File.delete (Fpath.v "log"))
      "clean"

  (* FIXME: describe init *)
  let describe _info ~dotcmd ~dot ~output (_init, job) =
    let f fmt = (if dot then Config.pp_dot else Config.pp) fmt job in
    let with_fmt f = match output with
      | None when dot ->
        f Format.str_formatter ;
        let data = Format.flush_str_formatter () in
        Bos.OS.File.tmp ~mode:0o644 "graph%s.dot" >>= fun tmp ->
        Bos.OS.File.write tmp data >>= fun () ->
        Bos.OS.Cmd.run Bos.Cmd.(v dotcmd % p tmp)
      | None -> Ok (f Fmt.stdout)
      | Some s ->
        with_output (Fpath.v s)
          (fun oc () -> Ok (f (Format.formatter_of_out_channel oc)))
    in
    with_fmt f

  (* Compile the configuration file and attempt to dynlink it.
   * It is responsible for registering an application via
   * [register] in order to have an observable
   * side effect to this command. *)
  let compile_and_dynlink file =
    Log.info (fun m -> m "Processing: %a" Fpath.pp file);
    let root, config = Fpath.(split_base file) in
    let file = Dynlink.adapt_filename (Fpath.to_string config) in
    let cfg = Fpath.rem_ext config in
    Bos.OS.Path.matches Fpath.(root / "_build" // cfg + "$(ext)") >>= fun files ->
    List.fold_left (fun r p -> r >>= fun () -> Bos.OS.Path.delete p) (R.ok ()) files >>= fun () ->
    with_current root
      (fun () ->
         let cmd =
           Bos.Cmd.(v "ocamlbuild" % "-use-ocamlfind" % "-classic-display" %
                    "-tags" % "bin_annot,color(always)" %
                    "-X" % "_build-ukvm" % "-pkg" % P.name % file)
         in
         Bos.OS.Cmd.(run_out cmd |> to_null) >>= fun _ ->
         try Ok (Dynlink.loadfile Fpath.(to_string (root / "_build" / file)))
         with Dynlink.Error err ->
           Log.err (fun m -> m "Error loading config: %s" (Dynlink.error_message err));
           Error (`Msg "error loading configuration"))
      "compile and dynlink"

  (* If a configuration file is specified, then use that.
   * If not, then scan the curdir for a `config.ml` file.
   * If there is more than one, then error out. *)
  let scan_conf c =
    let f =
      match c with
      | None -> "config.ml"
      | Some f -> f
    in
    Log.info (fun m -> m "Config file: %s" f);
    begin match Bos.OS.File.exists (Fpath.v f) with
      | Ok true ->
        Bos.OS.Dir.current () >>= fun dir ->
        Ok Fpath.(dir // v f)
      | Ok false ->
        Log.err (fun m -> m "%s does not exist, stopping." f);
        Error (`Msg "config does not exist")
      | Error (`Msg e) ->
        Log.err (fun m -> m "error while trying to access %s, stopping." f);
        Error (`Msg e)
    end

  module Config' = struct
    let pp_info (f:('a, Format.formatter, unit) format -> 'a) level info =
      let verbose = Logs.level () >= level in
      f "@[<v>%a@]" (Info.pp verbose) info

    let eval_cached ~partial context t =
      let info c = Config.eval ~partial c t in
      let f c = Key.eval c (info c) c in
      Cmdliner.Term.(pure f $ ret @@ pure @@ Cache.require context)

    let eval ~partial ~with_required context t =
      let info = Config.eval ~partial context t in
      let context =
        Key.context ~with_required ~stage:`Configure (Key.deps info)
      in
      let f map = Key.eval map info map in
      Cmdliner.Term.(pure f $ context)
  end

  let load' file =
    scan_conf file >>= fun file ->
    set_config_file (Fpath.to_string file);
    compile_and_dynlink file >>= fun () ->
    registered () >>= fun t ->
    Log.info (fun m -> m "using configuration %s" (Config.name t));
    Ok t

  let base_keys : Key.Set.t = Config.extract_keys (P.create [])
  let base_context_arg = Key.context base_keys
      ~with_required:false ~stage:`Configure

  let handle_parse_args_result = let module Cmd = Functoria_command_line in
    function
    | `Error _ -> exit 1
    | `Ok Cmd.Help -> ()
    | `Ok (Cmd.Configure (jobs, info)) ->
      Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
      R.error_msg_to_invalid_arg (configure info jobs)
    | `Ok (Cmd.Build (jobs, info)) ->
      Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
      R.error_msg_to_invalid_arg (build info jobs)
    | `Ok (Cmd.Describe { result = (jobs, info); dotcmd; dot; output }) ->
      Config'.pp_info Fmt.(pf stdout) (Some Logs.Info) info;
      R.error_msg_to_invalid_arg (describe info jobs ~dotcmd ~dot ~output)
    | `Ok (Cmd.Clean (jobs, info)) ->
      Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
      R.error_msg_to_invalid_arg (clean info jobs)
    | `Version
    | `Help -> ()

  let handle_parse_args_no_config error argv =
    let module Cmd = Functoria_command_line in
    let open Cmdliner in
    let result = Functoria_command_line.parse_args ~name:P.name ~version:P.version
        ~configure:(Term.pure ())
        ~describe:(Term.pure ())
        ~build:(Term.pure ())
        ~clean:(Term.pure ())
        ~help:base_context_arg
        argv
    in
    match result with
    | `Ok Cmd.Help -> ()
    | `Error _
    | `Ok (Cmd.Configure _ | Cmd.Describe _ | Cmd.Build _ | Cmd.Clean _) ->
      R.error_msg_to_invalid_arg (Error error)
    | `Version
    | `Help -> ()

  let run_with_argv argv =
    let module Cmd = Functoria_command_line in
    (* 1. Pre-parse the arguments to load the config file, set the log
     *    level, and determine whether the graph should be fully
     *    evaluated. *)
    ignore (Cmdliner.Term.eval_peek_opts ~argv Cmd.setup_log);

    (*    (c) whether to fully evaluate the graph *)
    let full_eval = Cmd.read_full_eval argv in

    (*    (d) the config file passed as argument, if any *)
    let config_file = Cmd.read_config_file argv in

    (* 2. Load the config from the config file. *)
    (* There are three possible outcomes:
         1. the config file is found and loaded successfully
         2. no config file is specified
         3. an attempt is made to access the base keys at this point.
            when they weren't loaded *)

    match load' config_file with
    | Error err -> handle_parse_args_no_config err argv
    | Ok config ->

       let config_keys = Config.keys config in
       let context_args =
         Key.context ~stage:`Configure ~with_required:false config_keys
       in

       let cached_context = Cache.get_context config.root context_args in
       let context =
         match Cmdliner.Term.eval_peek_opts ~argv context_args with
         | _, `Ok context -> context
         | _ -> Functoria_key.empty_context
       in

       (* 3. Parse the command-line and handle the result. *)

       let configure =
         Config'.eval ~with_required:true ~partial:false context config
       and describe =
         let context = Cache.merge ~cache:cached_context context in
         let partial = match full_eval with
           | Some true  -> false
           | Some false -> true
           | None -> not (Cache.present cached_context)
         in
         Config'.eval ~with_required:false ~partial context config
       and build =
         Config'.eval_cached ~partial:false cached_context config
       and clean =
         Config'.eval_cached ~partial:false cached_context config
       in

       handle_parse_args_result
         (Functoria_command_line.parse_args ~name:P.name ~version:P.version
            ~configure
            ~describe
            ~build
            ~clean
            ~help:base_context_arg
            argv)

  let run () = run_with_argv Sys.argv
end
