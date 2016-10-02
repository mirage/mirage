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

(* Keys *)

module Keys = struct

  let configure i =
    let file = String.lowercase Key.module_name ^ ".ml" in
    Log.info "%a %s" Log.blue "Generating:"  file;
    Cmd.with_file (Info.root i / file) @@ fun fmt ->
    Codegen.append fmt "(* %s *)" (Codegen.generated_header ());
    Codegen.newline fmt;
    let keys = Key.Set.of_list @@ Info.keys i in
    let pp_var k = Key.serialize (Info.context i) k in
    Fmt.pf fmt "@[<v>%a@]@." (Fmt.iter Key.Set.iter pp_var) keys;
    let runvars = Key.Set.elements (Key.filter_stage `Run keys) in
    let pp_runvar ppf v = Fmt.pf ppf "%s_t" (Key.ocaml_name v) in
    Codegen.append fmt "let runtime_keys = %a" Fmt.Dump.(list pp_runvar) runvars;
    Codegen.newline fmt;
    R.ok ()

  let clean i =
    let file = String.lowercase Key.module_name ^ ".ml" in
    R.ok @@ Cmd.remove (Info.root i / file)

  let name = "key"

end

let keys (argv: argv impl) = impl @@ object
    inherit base_configurable
    method ty = job
    method name = Keys.name
    method module_name = Key.module_name
    method !configure = Keys.configure
    method !clean = Keys.clean
    method !libraries = Key.pure [ "functoria.runtime" ]
    method !packages = Key.pure [ "functoria" ]
    method !deps = [ abstract argv ]
    method !connect info modname = function
      | [ argv ] ->
        Fmt.strf
          "return (Functoria_runtime.with_argv %s.runtime_keys %S %s)"
          modname (Info.name info) argv
      | _ -> failwith "The keys connect should receive exactly one argument."
  end

(* Module emiting a file containing all the build information. *)

type info = Info
let info = Type Info

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
    pp_packages (Info.packages i)
    pp_libraries (Info.libraries i)

let app_info ?(type_modname="Functoria_info")  ?(gen_modname="Info_gen") () =
  impl @@ object
    inherit base_configurable
    method ty = info
    method name = "info"
    val gen_file = String.lowercase gen_modname  ^ ".ml"
    method module_name = gen_modname
    method !libraries = Key.pure ["functoria.runtime"]
    method !packages = Key.pure ["functoria"]
    method !connect _ modname _ = Fmt.strf "return %s.info" modname

    method !clean i =
      let file = Info.root i / gen_file in
      Cmd.remove file;
      Cmd.remove (file ^".in");
      R.ok ()

    method !configure i =
      let file = Info.root i / gen_file in
      Log.info "%a %s" Log.blue "Generating: " gen_file;
      let f fmt =
        Fmt.pf fmt "@[<v 2>let info = %a@]" (pp_dump_info type_modname) i
      in
      Cmd.with_file (file^".in") f;
      Cmd.run ~redirect:false "opam config subst %s" gen_file
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
    type t = String.Set.t Key.value
    let union x y = Key.(pure String.Set.union $ x $ y)
    let empty = Key.pure String.Set.empty
  end

  let packages =
    let open Graph in
    Graph.collect (module M) @@ function
    | Impl c     -> Key.map String.Set.of_list c#packages
    | If _ | App -> M.empty

  let libraries =
    let open Graph in
    Graph.collect (module M) @@ function
    | Impl c     -> Key.map String.Set.of_list c#libraries
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
      let prefix = try String.(sub base 0 @@ index base '.') with _ -> base in
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
    libraries: String.Set.t Key.value;
    packages: String.Set.t Key.value;
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

  let make ?(keys=[]) ?(libraries=[]) ?(packages=[]) ?(init=[]) name root
      main_dev =
    let jobs = Graph.create main_dev in
    let libraries = Key.pure @@ String.Set.of_list libraries in
    let packages = Key.pure @@ String.Set.of_list packages in
    let keys = Key.Set.(union (of_list keys) (get_if_context jobs)) in
    { libraries; packages; keys; name; root; init; jobs }

  let eval ~partial context
      { name = n; root; packages; libraries; keys; jobs; init }
    =
    let e = Graph.eval ~partial ~context jobs in
    let pkgs = Key.(pure String.Set.union $ packages $ Engine.packages e) in
    let libs = Key.(pure String.Set.union $ libraries $ Engine.libraries e) in
    let keys = Key.Set.elements (Key.Set.union keys @@ Engine.keys e) in
    Key.(pure (fun libraries packages _ context ->
        ((init, e),
         Info.create
           ~libraries:(String.Set.elements libraries)
           ~packages:(String.Set.elements packages)
           ~keys ~context ~name:n ~root))
         $ libs
         $ pkgs
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

module type S = sig
  val prelude: string
  val name: string
  val version: string
  val create: job impl list -> job impl
end

module type DSL = module type of struct include Functoria end

module Make (P: S) = struct

  let () = Log.set_section P.name

  let configuration = ref None
  let config_file = ref None

  let set_config_file f =
    config_file := Some f

  let get_config_file () =
    match !config_file with
    | None -> Sys.getcwd () / "config.ml"
    | Some f -> f

  let get_root () = Filename.dirname @@ get_config_file ()

  let register ?(packages=[]) ?(libraries=[]) ?keys ?(init=[]) name jobs =
    let keys = match keys with None -> [] | Some x -> x in
    let root = get_root () in
    let main_dev = P.create (init @ jobs) in
    let c = Config.make ~keys ~libraries ~packages ~init name root main_dev in
    configuration := Some c

  let registered () =
    match !configuration with
    | None   -> Log.error "No configuration was registered."
    | Some t -> Ok t

  (* {2 Opam Management} *)

  let configure_opam ~no_opam_version ~no_depext t =
    Log.info "Installing OPAM packages.";
    let ps = Info.packages t in
    if ps = [] then Ok ()
    else if Cmd.exists "opam" then
      if no_opam_version then Ok ()
      else (
        Cmd.read "opam --version" >>= fun opam_version ->
        let version_error () =
          Log.error
            "Your version of OPAM (%s) is not recent enough. \
             Please update to (at least) 1.2: \
             https://opam.ocaml.org/doc/Install.html \
             You can pass the `--no-opam-version-check` flag to force its \
             use." opam_version
        in
        match String.split opam_version '.' with
        | major::minor::_ ->
          let major = try int_of_string major with Failure _ -> 0 in
          let minor = try int_of_string minor with Failure _ -> 0 in
          let color = Log.get_color () in
          if (major, minor) >= (1, 2) then (
            begin
              if no_depext then Ok ()
              else begin
                if Cmd.exists "opam-depext"
                then Ok (Log.info "opam depext is installed.")
                else Cmd.opam ?color "install" ["depext"]
              end >>= fun () -> Cmd.opam "depext" ps
            end >>= fun () ->
            Cmd.opam ?color "install" ps
          ) else version_error ()
        | _ -> version_error ()
      )
    else Log.error "OPAM is not installed."

  let configure_main i jobs =
    Log.info "%a main.ml" Log.blue "Generating:";
    Codegen.set_main_ml (Info.root i / "main.ml");
    Codegen.append_main "(* %s *)" (Codegen.generated_header ());
    Codegen.newline_main ();
    Codegen.append_main "%a" Fmt.text  P.prelude;
    Codegen.newline_main ();
    Codegen.append_main "let _ = Printexc.record_backtrace true";
    Codegen.newline_main ();
    Engine.configure_and_connect i jobs >>| fun () ->
    Codegen.newline_main ();
    ()

  let clean_main i jobs =
    Engine.clean i jobs >>| fun () ->
    Cmd.remove (Info.root i / "main.ml")

  let configure ~no_opam ~no_depext ~no_opam_version i jobs =
    Log.info "%a %s" Log.blue "Using configuration:"  (get_config_file ());
    Cmd.in_dir (Info.root i) (fun () ->
        begin if no_opam
          then Ok ()
          else configure_opam ~no_depext ~no_opam_version i
        end >>= fun () ->
        configure_main i jobs
      )

  let make () =
    match Cmd.uname_s () with
    | Some ("FreeBSD" | "OpenBSD" | "NetBSD" | "DragonFly") -> "gmake"
    | _ -> "make"

  let build i =
    Log.info "%a %s" Log.blue "Build:" (get_config_file ());
    Cmd.in_dir (Info.root i) (fun () ->
        Cmd.run "%s build" (make ())
      )

  let clean i (_init, job) =
    Log.info "%a %s" Log.blue "Clean:"  (get_config_file ());
    let root = Info.root i in
    Cmd.in_dir root (fun () ->
        clean_main i job >>= fun () ->
        Cmd.run "rm -rf %s/_build" root >>= fun () ->
        Cmd.run "rm -rf log %s/main.native.o %s/main.native %s/*~" root
          root root
      )

  (* FIXME: describe init *)
  let describe _info ~dotcmd ~dot ~output (_init, job) =
    let f fmt = (if dot then Config.pp_dot else Config.pp) fmt job in
    let with_fmt f = match output with
      | None when dot ->
        let f oc = Cmd.with_channel oc f in
        Cmd.with_process_out dotcmd f
      | None -> f Fmt.stdout
      | Some s -> Cmd.with_file s f
    in R.ok @@ with_fmt f

  (* Compile the configuration file and attempt to dynlink it.
   * It is responsible for registering an application via
   * [register] in order to have an observable
   * side effect to this command. *)
  let compile_and_dynlink file =
    Log.info "%a %s" Log.blue "Processing:" file;
    let root = Filename.dirname file in
    let file = Filename.basename file in
    let file = Dynlink.adapt_filename file in
    Cmd.run "rm -rf %s/_build/%s.*" root (Filename.chop_extension file)
    >>= fun () ->
    Cmd.run
      "cd %s && ocamlbuild -use-ocamlfind -tags annot,bin_annot -pkg %s %s"
      root P.name file
    >>= fun () ->
    try Ok (Dynlink.loadfile (String.concat "/" [root; "_build"; file]))
    with Dynlink.Error err ->
      Log.error "Error loading config: %s" (Dynlink.error_message err)

  (* If a configuration file is specified, then use that.
   * If not, then scan the curdir for a `config.ml` file.
   * If there is more than one, then error out. *)
  let scan_conf = function
    | Some f ->
      Log.info "%a %s" Log.blue "Config file:" f;
      if not (Sys.file_exists f) then
        Log.error "%s does not exist, stopping." f
      else Ok (Cmd.realpath f)
    | None   ->
      let files = Array.to_list (Sys.readdir ".") in
      match List.filter ((=) "config.ml") files with
      | [] -> Log.error
                "No configuration file config.ml found.\n\
                 Please specify the configuration file using -f."
      | [f] ->
        Log.info "%a %s" Log.blue "Config file:" f;
        Ok (Cmd.realpath f)
      | _   ->
        Log.error
          "There is more than one config.ml in the current working \
           directory.\n\
           Please specify one explictly on the command-line."

  module Config' = struct
    let pp_info (f:('a, Format.formatter, unit) format -> 'a) level info =
      let verbose = Log.get_level () >= level in
      f "@[<v>%a@]" (Info.pp verbose) info

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
    let root = Cmd.realpath (Filename.dirname file) in
    let file = root / Filename.basename file in
    set_config_file file;
    compile_and_dynlink file >>= fun () ->
    registered () >>= fun t ->
    Log.set_section (Config.name t);
    Ok t

  let base_keys : Key.Set.t = Config.extract_keys (P.create [])
  let base_context_arg = Key.context base_keys
      ~with_required:false ~stage:`Configure

  let configure_colour color =
    let i = Functoria_misc.Terminfo.columns () in
    begin
      Functoria_misc.Log.set_color color;
      Format.pp_set_margin Format.std_formatter i;
      Format.pp_set_margin Format.err_formatter i;
      Fmt_tty.setup_std_outputs ?style_renderer:color ()
    end

  let handle_parse_args_result = let module Cmd = Functoria_command_line in
    function
    | `Error _ -> exit 1
    | `Ok Cmd.Help -> ()
    | `Ok (Cmd.Configure {result = (jobs, info); no_opam; no_depext; no_opam_version}) ->
      Config'.pp_info Log.info Log.DEBUG info;
      fatalize_error (configure info jobs ~no_opam ~no_depext ~no_opam_version)
    | `Ok (Cmd.Describe { result = (jobs, info); dotcmd; dot; output }) ->
      Config'.pp_info Fmt.(pf stdout) Log.INFO info;
      fatalize_error (describe info jobs ~dotcmd ~dot ~output)
    | `Ok (Cmd.Build (_, info)) ->
      Config'.pp_info Log.info Log.DEBUG info;
      fatalize_error (build info)
    | `Ok (Cmd.Clean (jobs, info)) ->
      Config'.pp_info Log.info Log.DEBUG info;
      fatalize_error (clean info jobs)
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
      Functoria_misc.Log.fatal "%s" error
    | `Version
    | `Help -> ()

  let run_with_argv argv =
    let module Cmd = Functoria_command_line in
    (* 1. Pre-parse the arguments to load the config file, set the log
     *    level and colour, and determine whether the graph should be fully
     *    evaluated. *)

    (*    (a) log level *)
    let () = Functoria_misc.Log.set_level (Cmd.read_log_level argv) in

    (*    (b) colour option *)
    let () = configure_colour (Cmd.read_colour_option argv) in

    (*    (c) whether to fully evaluate the graph *)
    let full_eval = Cmd.read_full_eval argv in

    (*    (d) the config file passed as argument, if any *)
    let config_file = Cmd.read_config_file argv in

    (* 2. Load the config from the config file. *)
    (* There are three possible outcomes:
         1. the config file is found and loaded succeessfully
         2. no config file is specified
         3. an attempt is made to access the base keys at this point.
            when they weren't loaded *)

    match load' config_file with
    | Error err -> handle_parse_args_no_config err argv
    | Ok config ->
       let config_keys = Config.keys config in
       let context_args = Key.context ~stage:`Configure ~with_required:false config_keys in
       let context =
         match Cmdliner.Term.eval_peek_opts ~argv context_args with
         | _, `Ok context -> context
         | _ -> Functoria_key.empty_context
       in

       (* 3. Parse the command-line and handle the result. *)
       handle_parse_args_result
         (Functoria_command_line.parse_args ~name:P.name ~version:P.version
            ~configure:(Config'.eval ~with_required:true ~partial:false context config)
            ~describe:(Config'.eval ~with_required:false ~partial:(not full_eval) context config)
            ~build:(Config'.eval ~with_required:false ~partial:false context config)
            ~clean:(Config'.eval ~with_required:false ~partial:false context config)
            ~help:base_context_arg
            argv)

  let run () =
    try
      run_with_argv Sys.argv
    with Functoria_misc.Log.Fatal s ->
      begin
        Functoria_misc.Log.show_error "%s" s;
        exit 1
      end
end
