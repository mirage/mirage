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
module KeySet = Set.Make(Key)

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
    method !connect _info _m _ =
      "return (`Ok Sys.argv)"
  end

(* Keys *)

module Keys = struct

  let configure i =
    let file = String.lowercase Key.module_name ^ ".ml" in
    Log.info "%a %s" Log.blue "Generating:"  file;
    Cmd.with_file (Info.root i / file) @@ fun fmt ->
    Codegen.append fmt "(* %s *)" (Codegen.generated_header ());
    Codegen.newline fmt;
    let bootvars = Info.keys i in
    Fmt.pf fmt "@[<v>%a@]@."
      (Fmt.iter List.iter @@ Key.serialize @@ Info.context i) bootvars;
    Codegen.append fmt "let runtime_keys = %a"
      Fmt.(Dump.list (fmt "%s_t"))
      (List.map Key.ocaml_name @@ Key.filter_stage `Run bootvars);
    Codegen.newline fmt;
    R.ok ()

  let clean i =
    let file = String.lowercase Key.module_name ^ ".ml" in
    R.ok @@ Cmd.remove (Info.root i / file)

  let name = "bootvar"

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

let pp_dump_info fmt i =
  Fmt.pf fmt
    "Functoria_info.{@ name = %S;@ \
     @[<v 2>packages = %a@]@ ;@ @[<v 2>libraries = %a@]@ }"
    (Info.name i)
    pp_packages (Info.packages i)
    pp_libraries (Info.libraries i)

let export_info = impl @@ object
    inherit base_configurable
    method ty = info
    method name = "info"

    val gen_file_name = "Config_info_gen"
    method module_name = "Functoria_info"
    method !libraries = Key.pure ["functoria.runtime"]
    method !packages = Key.pure ["functoria"]
    method !connect _ modname _ = Fmt.strf "return (`Ok %s.info)" modname

    method !clean i =
      let file = Info.root i / (String.lowercase gen_file_name ^ ".ml") in
      Cmd.remove file;
      Cmd.remove (file ^".in");
      R.ok ()

    method !configure i =
      let filename = String.lowercase gen_file_name ^ ".ml" in
      let file = Info.root i / filename in
      Log.info "%a %s" Log.blue "Generating: " filename;
      let f fmt =
        Fmt.pf fmt "@[<v 2>let info = %a@]" pp_dump_info i
      in
      Cmd.with_file (file^".in") f;
      Cmd.run ~redirect:false "opam config subst %s" filename
  end

module Engine = struct

  let switching_context =
    let open Graph in
    Graph.collect (module KeySet) @@ function
    | If cond      -> KeySet.of_list (Key.deps cond)
    | App | Impl _ -> KeySet.empty

  let keys =
    let open Graph in
    Graph.collect (module KeySet) @@ function
    | Impl c  -> KeySet.of_list c#keys
    | If cond -> KeySet.of_list (Key.deps cond)
    | App     -> KeySet.empty

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

  let find_bootvar g =
    let open Graph in
    let p = function
      | Impl c     -> c#name = Keys.name
      | App | If _ -> false
    in
    match Graph.find_all g p with
    | [ x ] -> x
    | _ -> invalid_arg
             "Functoria.find_bootvar: There should be only one bootvar device."

  let configure info g =
    let tbl = Graph.Tbl.create 17 in
    let f v = match Graph.explode g v with
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
    Graph.fold f g @@ R.ok () >>| fun () ->
    tbl

  let meta_init fmt (connect_name, result_name) =
    Fmt.pf fmt "let _%s =@[@ %s () @]in@ " result_name connect_name

  let meta_connect error fmt (connect_name, result_name) =
    Fmt.pf fmt
      "_%s >>= function@ \
       | `Error _e -> %s@ \
       | `Ok %s ->@ "
      result_name
      (error connect_name)
      result_name

  let emit_connect fmt (error, iname, names, connect_string) =
    (* We avoid potential collision between double application
       by prefixing with "_". This also avoid warnings. *)
    let names = List.map (fun x -> (x, "_"^x)) names in
    Fmt.pf fmt
      "@[<v 2>let %s () =@ \
       %a\
       %a\
       %s@]@."
      iname
      Fmt.(list ~sep:nop meta_init) names
      Fmt.(list ~sep:nop @@ meta_connect error) names
      (connect_string @@ List.map snd names)

  let connect modtbl info error g =
    let tbl = Graph.Tbl.create 17 in
    let f v =
      match Graph.explode g v with
      | `App _ | `If _ -> assert false
      | `Impl (c, `Args args, `Deps deps) ->
        let ident = name c (Graph.hash v) in
        let modname = Graph.Tbl.find modtbl v in
        Graph.Tbl.add tbl v ident;
        let names = List.map (Graph.Tbl.find tbl) (args @ deps) in
        Codegen.append_main "%a"
          emit_connect (error, ident, names, c#connect info modname)
    in
    Graph.fold (fun v () -> f v) g ();
    let main_name = Graph.Tbl.find tbl @@ Graph.find_root g in
    let bootvar_name = Graph.Tbl.find tbl @@ find_bootvar g in
    Codegen.append_main
      "let () = run (%s () >>= fun _ -> %s ())"
      bootvar_name main_name;
    ()

  let configure_and_connect info error g =
    configure info g >>| fun modtbl ->
    connect modtbl info error g

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
    keys    : KeySet.t;
    jobs    : Graph.t;
  }

  (* In practice, we get all the switching keys and all the keys that
     have a setter to them. *)
  let get_switching_context jobs =
    let all_keys = Engine.keys jobs in
    let skeys = Engine.switching_context jobs in
    let f k s =
      if KeySet.is_empty @@ KeySet.inter (KeySet.of_list @@ Key.aliases k) skeys
      then s
      else KeySet.add k s
    in
    KeySet.fold f all_keys skeys

  let make ?(keys=[]) ?(libraries=[]) ?(packages=[]) name root main_dev =
    let jobs = Graph.create main_dev in
    let libraries = Key.pure @@ String.Set.of_list libraries in
    let packages = Key.pure @@ String.Set.of_list packages in
    let keys = KeySet.(union (of_list keys) (get_switching_context jobs)) in
    { libraries; packages; keys; name; root; jobs }

  (* FIXME(samoht): I don't understand why eval return a function
     which take a context. Is this supposed to be different from the
     one passed as argument? *)
  let eval context { name = n; root; packages; libraries; keys; jobs } =
    let e = Graph.eval ~context:context jobs in
    let open Key in
    let packages = pure String.Set.union $ packages $ Engine.packages e in
    let libraries = pure String.Set.union $ libraries $ Engine.libraries e in
    let keys = KeySet.elements (KeySet.union keys @@ Engine.keys e) in
    let list = String.Set.elements in
    let di =
      pure (fun libraries packages context ->
          e, Info.create ~libraries:(list libraries) ~packages:(list packages)
            ~keys ~context ~name:n ~root)
      $ libraries
      $ packages
    in
    with_deps keys di

  (* Extract all the keys directly. Useful to pre-resolve the keys
     provided by the specialized DSL. *)
  let extract_keys impl =
    Engine.keys @@ Graph.create impl

  let name t = t.name
  let keys t = t.keys

  let gen_pp pp ~partial ~context fmt jobs =
    pp fmt @@ Graph.simplify @@ Graph.eval ~partial ~context jobs

  let pp = gen_pp Graph.pp
  let pp_dot = gen_pp Graph.pp_dot

end

module type S = sig
  val prelude: string
  val name: string
  val version: string
  val driver_error: string -> string
  val argv: argv impl
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

  let register ?(packages=[]) ?(libraries=[]) ?keys:ckeys name jobs =
    let ckeys = match ckeys with None -> [] | Some x -> x in
    let root = get_root () in
    let main_dev = P.create (keys P.argv :: jobs) in
    let c = Config.make ~keys:ckeys ~libraries ~packages name root main_dev in
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
          if (major, minor) >= (1, 2) then (
            begin
              if no_depext then Ok ()
              else begin
                if Cmd.exists "opam-depext"
                then Ok (Log.info "opam depext is installed.")
                else Cmd.opam "install" ["depext"]
              end >>= fun () -> Cmd.opam ~yes:false "depext" ps
            end >>= fun () ->
            Cmd.opam "install" ps
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
    Engine.configure_and_connect i P.driver_error jobs >>| fun () ->
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

  let clean i jobs =
    Log.info "%a %s" Log.blue "Clean:"  (get_config_file ());
    let root = Info.root i in
    Cmd.in_dir root (fun () ->
        clean_main i jobs >>= fun () ->
        Cmd.run "rm -rf %s/_build" root >>= fun () ->
        Cmd.run "rm -rf log %s/main.native.o %s/main.native %s/*~" root
          root root
      )

  let describe ~dotcmd ~dot ~eval ~output ~context { Config.jobs; _ } =
    let f fmt =
      Config.(if dot then pp_dot else pp) ~partial:(not eval) ~context fmt jobs
    in
    let with_fmt f = match output with
      | None when dot ->
        let f oc = Cmd.with_channel oc f in
        Cmd.with_process_out dotcmd f
      | None -> f Fmt.stdout
      | Some s -> Cmd.with_file s f
    in R.ok @@ with_fmt f

  let show_keys keymap keyset =
    Log.info "%a %a" Log.blue "Keys:" (Key.pps keymap) keyset

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
                 Please precise the configuration file using -f."
      | [f] ->
        Log.info "%a %s" Log.blue "Config file:" f;
        Ok (Cmd.realpath f)
      | _   ->
        Log.error
          "There is more than one config.ml in the current working \
           directory.\n\
           Please specify one explictly on the command-line."

  module C = struct
    include P

    (* This is a hack to allow the implementation of
       [Mirage.get_mode]. Once it is removed, the notion of base context
       should be removed as well. *)
    let base_context = ref None
    let get_base_context () = match !base_context with
      | Some x -> x
      | None ->
        invalid_arg "Base key map is not available at this point. Please stop \
                     messing with functoria's invariants."

    let base_context =
      let keys = KeySet.elements @@ Config.extract_keys (P.create []) in
      let context = Key.context ~stage:`Configure keys in
      let f x = base_context := Some x; x in
      Cmdliner.Term.(pure f $ context)

    type t = Config.t
    type evaluated = Graph.t * Info.t

    let load file =
      scan_conf file >>= fun file ->
      let root = Cmd.realpath (Filename.dirname file) in
      let file = root / Filename.basename file in
      set_config_file file;
      compile_and_dynlink file >>= fun () ->
      registered () >>= fun t ->
      Log.set_section (Config.name t);
      Ok t

    let switching_context t =
      Key.context ~stage:`Configure @@ KeySet.elements @@ Config.keys t

    let configure (jobs, info) = configure info jobs
    let clean (jobs, info) = clean info jobs
    let build (_jobs, info) = build info
    let describe context t = describe ~context t

    (* FIXME: switch_map? *)
    let eval switch_map t =
      let info = Config.eval switch_map t in
      let context = Key.context ~stage:`Configure (Key.deps info) in
      let f map =
        show_keys map @@ Key.deps info;
        Key.eval map info @@ map
      in
      Cmdliner.Term.(pure f $ context)
  end

  let get_base_context = C.get_base_context
  let run () = let module M = Functoria_tool.Make(C) in ()

end
