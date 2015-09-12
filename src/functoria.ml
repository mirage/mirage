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

open Functoria_misc
open Rresult

module Dsl = Functoria_dsl
module G = Functoria_graph

open Dsl

module Devices = struct

  (** Default argv *)

  type argv = ARGV
  let argv = Type ARGV

  let sys_argv = impl @@ object
      inherit base_configurable
      method ty = argv
      method name = "argv"
      method module_name = "Sys"
      method! connect _info _m _ =
        "Lwt.return (`Ok Sys.argv)"
    end

  (** Keys *)

  let configure_keys i =
    let file = String.lowercase Key.module_name ^ ".ml" in
    info "%a %s" blue "Generating:"  file;
    with_file (Info.root i / file) @@ fun fmt ->
    Codegen.append fmt "(* %s *)" (generated_header "Functoria") ;
    Codegen.newline fmt;
    let bootvars = Info.keys i in
    Fmt.pf fmt "@[<v>%a@]@."
      (Fmt.iter Key.Set.iter @@ Key.emit) bootvars ;
    Codegen.append fmt "let runtime_keys = %a"
      Fmt.(Dump.list (fmt "%s_t"))
      (List.map Key.ocaml_name @@
       Key.Set.elements @@ Key.Set.filter_stage ~stage:`Run bootvars);
    Codegen.newline fmt

  let clean_keys i =
    let file = String.lowercase Key.module_name ^ ".ml" in
    remove (Info.root i / file)

  let keys (argv : argv impl) = impl @@ object
      inherit base_configurable
      method ty = job
      method name = "bootvar"
      method module_name = Key.module_name
      method! configure = configure_keys
      method! clean = clean_keys
      method! dependencies = [ hide argv ]
      method! connect info modname = function
        | [ argv ] ->
          Fmt.strf
            "Functoria_runtime.with_argv %s.keys %S %s"
            modname (Info.name info) argv
        | _ -> failwith "The keys connect should receive exactly one argument."
    end
end



module Engine = struct

  let switching_keys =
    G.collect (module Key.Set) @@ function
    | G.If cond -> Key.deps cond
    | _ -> Key.Set.empty

  let keys =
    G.collect (module Key.Set) @@ function
    | G.Impl c -> Key.Set.of_list c#keys
    | _ -> Key.Set.empty


  module M = struct
    type t = StringSet.t Key.value
    let union x y = Key.(pure StringSet.union $ x $ y)
    let empty = Key.pure StringSet.empty
  end

  let packages =
    G.collect (module M) @@ function
    | G.Impl c -> Key.map StringSet.of_list c#packages
    | _ -> M.empty

  let libraries =
    G.collect (module M) @@ function
    | G.Impl c -> Key.map StringSet.of_list c#libraries
    | _ -> M.empty


  (** Return a unique variable name holding the state of the given
      module construction. *)
  let name tbl c args deps =
    let base = Key.ocamlify c#name in
    if args = [] && deps = [] then base
    else
      let s =
        Fmt.strf "%s%a"
          base   Fmt.(list ~sep:nop @@ of_to_string @@ G.Tbl.find tbl) args
      in Name.of_key s ~base

  (** [module_expresion tbl c args] returns the module expression of the
      functor [c] applies to [args]. *)
  let module_expression tbl fmt (c, args) =
    Fmt.pf fmt "%s%a"
      c#module_name
      Fmt.(list @@ parens @@ of_to_string @@ G.Tbl.find tbl)
      args

  (** [module_name tbl c args] return the module name of the result of the
      functor application.
      If [args = []], it returns [c#module_name]. *)
  let module_name tbl c args =
    let base = c#module_name in
    if args = [] then base
    else
      let n = Fmt.strf "%a" (module_expression tbl) (c, args) in
      let base = Key.ocamlify String.(sub base 0 (index base '.')) in
      Name.of_key n ~base


  let configure info g =
    let tbl = G.Tbl.create 17 in
    let f v = match G.explode g v with
      | `App _ | `If _ -> assert false
      | `Impl (c, `Args args, `Deps _) ->
        let modname = module_name tbl c args in
        G.Tbl.add tbl v modname ;
        c#configure info ;
        if args = [] then ()
        else begin
          Codegen.append_main
            "@[<2>module %s =@ %a@]"
            modname
            (module_expression tbl) (c,args);
          Codegen.newline_main ();
        end
    in
    G.iter g f ;
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
    let tbl = G.Tbl.create 17 in
    let f v =
      match G.explode g v with
      | `App _ | `If _ -> assert false
      | `Impl (c, `Args args, `Deps deps) ->
        let ident = name tbl c args deps in
        let modname = G.Tbl.find modtbl v in
        G.Tbl.add tbl v ident ;
        let names = List.map (G.Tbl.find tbl) (args @ deps) in
        Codegen.append_main "%a"
          emit_connect (error, ident, names, c#connect info modname)
    in
    G.iter g f ;
    let main = G.Tbl.find tbl @@ G.find_root g in
    Codegen.append_main
      "let () = run (bootvar () >>= fun _ -> %s ())" main ;
    ()

  let configure_and_connect info error g =
    let modtbl = configure info g in
    connect modtbl info error g

  let clean i g =
    G.iter g @@ fun v -> match G.explode g v with
    | `Impl (c,_,_) -> c#clean i
    | _ -> ()

end

module Config = struct

  type t = {
    name : string ;
    root : string ;
    libraries : StringSet.t Key.value ;
    packages : StringSet.t Key.value ;
    keys : Key.Set.t ;
    jobs : G.t ;
  }

  let make
      ?(keys=[]) ?(libraries=[]) ?(packages=[])
      name root jobs init_dsl =
    let custom = init_dsl ~name ~root jobs in
    let jobs = G.create @@ impl custom in

    let libraries = Key.pure @@ StringSet.of_list libraries in
    let packages = Key.pure @@ StringSet.of_list packages in
    let keys =
      Key.Set.(union (of_list (keys @ custom#keys)) (Engine.switching_keys jobs))
    in
    { libraries ; packages ; keys ; name ; root ; jobs }

  let eval { name = n ; root ; packages ; libraries ; keys ; jobs } =
    let e = G.eval @@ G.normalize jobs in
    let open Key in
    let packages = pure StringSet.union $ packages $ Engine.packages e in
    let libraries = pure StringSet.union $ libraries $ Engine.libraries e in
    let keys = Key.Set.union keys @@ Engine.keys e in
    let di =
      pure (fun libraries packages ->
        {Info. libraries ; packages ; keys ; name = n ; root})
      $ libraries
      $ packages
    in
    e, with_deps ~keys di

  let name t = t.name
  let switching_keys t = t.keys

  let gen_pp pp normalize fmt t =
    let f = if normalize then G.normalize else G.remove_partial_app in
    pp fmt @@ f @@ G.eval ~partial:true t.jobs

  let pp = gen_pp G.pp
  let pp_dot = gen_pp G.pp_dot
end

module type PROJECT = sig

  val prelude : string

  val name : string

  val version : string

  val driver_error : string -> string

  val argv : Devices.argv impl

  val configurable :
    name:string -> root:string -> job impl list ->
    job configurable

end

module Make (P:PROJECT) = struct
  module Project = P

  let key_device = Devices.keys P.argv

  let () = set_section P.name

  let configuration = ref None
  let config_file = ref None

  let set_config_file f =
    config_file := Some f

  let get_config_file () =
    match !config_file with
    | None -> Sys.getcwd () / "config.ml"
    | Some f -> f
  let get_root () = Filename.dirname @@ get_config_file ()

  let register ?(keys=[]) ?(libraries=[]) ?(packages=[]) name jobs =
    let root = get_root () in
    let jobs = key_device :: jobs in
    let c =
      Config.make ~keys ~libraries ~packages name root jobs P.configurable
    in
    configuration := Some c


  let registered () =
    match !configuration with
    | None   -> error "No configuration was registered."
    | Some t -> Ok t

  (** {2 Opam Management} *)

  let configure_opam ~no_opam_version ~no_depext t =
    info "Installing OPAM packages.";
    let ps = Info.packages t in
    if StringSet.is_empty ps then Ok ()
    else
    if command_exists "opam" then
      if no_opam_version then Ok ()
      else (
        read_command "opam --version" >>= fun opam_version ->
        let version_error () =
          error "Your version of OPAM (%s) is not recent enough. \
                 Please update to (at least) 1.2: https://opam.ocaml.org/doc/Install.html \
                 You can pass the `--no-opam-version-check` flag to force its use." opam_version
        in
        match split opam_version '.' with
        | major::minor::_ ->
          let major = try int_of_string major with Failure _ -> 0 in
          let minor = try int_of_string minor with Failure _ -> 0 in
          if (major, minor) >= (1, 2) then (
            let ps = StringSet.elements ps in
            if no_depext then Ok ()
            else (
              begin
                if command_exists "opam-depext"
                then Ok (info "opam depext is installed.")
                else opam "install" ["depext"]
              end >>= fun () -> opam ~yes:false "depext" ps
            ) >>= fun () ->
              opam "install" ps
          ) else version_error ()
        | _ -> version_error ()
      )
    else error "OPAM is not installed."

  let clean_opam _t =
    ()
  (* This is a bit too agressive, disabling for now on.
     let (++) = StringSet.union in
     let set mode = StringSet.of_list (packages t mode) in
     let packages =
      set (`Unix `Socket) ++ set (`Unix `Direct) ++ set `Xen in
     match StringSet.elements packages with
     | [] -> ()
     | ps ->
      if cmd_exists "opam" then opam "remove" ps
      else error "OPAM is not installed."
  *)


  let configure_main i jobs =
    info "%a main.ml" blue "Generating:";
    Codegen.set_main_ml (Info.root i / "main.ml");
    Codegen.append_main "(* %s *)" (generated_header P.name);
    Codegen.newline_main ();
    Codegen.append_main "%a" Fmt.text  Project.prelude;
    Codegen.newline_main ();
    Codegen.append_main "let _ = Printexc.record_backtrace true";
    Codegen.newline_main ();
    Engine.configure_and_connect i Project.driver_error jobs;
    Codegen.newline_main ();
    ()

  let clean_main i jobs =
    Engine.clean i jobs ;
    remove (Info.root i / "main.ml")

  let configure ~no_opam ~no_depext ~no_opam_version i jobs =
    info "%a %s" blue "Using configuration:"  (get_config_file ());
    in_dir (Info.root i) (fun () ->
      begin if no_opam
        then Ok ()
        else configure_opam ~no_depext ~no_opam_version i
      end >>= fun () ->
      configure_main i jobs;
      Ok ()
    )

  let make () =
    match uname_s () with
    | Some ("FreeBSD" | "OpenBSD" | "NetBSD" | "DragonFly") -> "gmake"
    | _ -> "make"

  let build i =
    info "%a %s" blue "Build:" (get_config_file ());
    in_dir (Info.root i) (fun () ->
      command "%s build" (make ())
    )

  let clean ~no_opam i jobs =
    info "%a %s" blue "Clean:"  (get_config_file ());
    let root = Info.root i in
    in_dir root (fun () ->
      if not no_opam then clean_opam ();
      clean_main i jobs;
      command "rm -rf %s/_build" root >>= fun () ->
      command "rm -rf log %s/main.native.o %s/main.native %s/*~"
        root root root ;
    )

  let describe g ~dotcmd ~dot ~normalize file =
    let f fmt = Config.(if dot then pp_dot else pp) normalize fmt g in
    let with_fmt f = match file with
      | None when dot ->
        let f oc = with_channel oc f in
        with_process_out dotcmd f
      | None -> f Fmt.stdout
      | Some s -> with_file s f
    in with_fmt f

  (* Compile the configuration file and attempt to dynlink it.
   * It is responsible for registering an application via
   * [register] in order to have an observable
   * side effect to this command. *)
  let compile_and_dynlink file =
    info "%a %s" blue "Processing:" file;
    let root = Filename.dirname file in
    let file = Filename.basename file in
    let file = Dynlink.adapt_filename file in
    command
      "rm -rf %s/_build/%s.*"
      root (Filename.chop_extension file)
    >>= fun () ->
    command
      "cd %s && ocamlbuild -use-ocamlfind -tags annot,bin_annot -pkg %s %s"
      root P.name file
    >>= fun () ->
    try Ok (Dynlink.loadfile (String.concat "/" [root; "_build"; file]))
    with Dynlink.Error err -> error "Error loading config: %s" (Dynlink.error_message err)

  (* If a configuration file is specified, then use that.
   * If not, then scan the curdir for a `config.ml` file.
   * If there is more than one, then error out. *)
  let scan_conf = function
    | Some f ->
      info "%a %s" blue "Config file:" f;
      if not (Sys.file_exists f) then error "%s does not exist, stopping." f
      else Ok (realpath f)
    | None   ->
      let files = Array.to_list (Sys.readdir ".") in
      match List.filter ((=) "config.ml") files with
      | [] -> error "No configuration file config.ml found.\n\
                     Please precise the configuration file using -f."
      | [f] ->
        info "%a %s" blue "Config file:" f;
        Ok (realpath f)
      | _   -> error "There is more than one config.ml in the current working directory.\n\
                      Please specify one explictly on the command-line."

  module C = struct
    include Project

    let dummy_conf =
      let name = P.name and root = get_root () in
      Config.make name root [] P.configurable

    type t = Config.t
    type info = Info.t

    let load file =
      scan_conf file >>= fun file ->
      let root = realpath (Filename.dirname file) in
      let file = root / Filename.basename file in
      set_config_file file;
      compile_and_dynlink file >>= fun () ->
      registered () >>= fun t ->
      set_section (Config.name t);
      Ok t

    let switching_keys t =
      Key.term ~stage:`Configure @@ Config.switching_keys t

    let eval t =
      let evaluated, info = Config.eval t in
      object
        method configure info = configure info evaluated
        method clean info = clean info evaluated
        method build info = build info
        method info = Key.term_value ~stage:`Configure info
        method describe = describe t
      end
  end

  include Dsl

  let launch () =
    let module M = Functoria_tool.Make(C) in
    ()

end

module type S = Functoria_sigs.S
  with module Key := Functoria_key
   and module Info := Info
   and type 'a impl = 'a impl
   and type 'a typ = 'a typ
   and type any_impl = any_impl
   and type job = job
   and type 'a configurable = 'a configurable

module type KEY = Functoria_sigs.KEY
  with type 'a key = 'a Key.key
   and type 'a value = 'a Key.value
   and type t = Key.t
   and type Set.t = Key.Set.t
