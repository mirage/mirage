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

module Dsl = Functoria_dsl
module G = Functoria_graph
module Misc = Functoria_misc

open Dsl
open Misc

module Devices = struct

  (** Noop, the job that does nothing. *)

  let noop = impl @@ object
      inherit base_configurable
      method ty = job
      method name = "noop"
      method module_name = "Pervasives"
    end

  (** Default argv *)

  type argv = ARGV
  let argv = Type ARGV

  let sys_argv = impl @@ object
      inherit base_configurable
      method ty = argv
      method name = "argv"
      method module_name = "Sys"
      method connect _info _m _ =
        "return (`Ok Sys.argv)"
    end

  (** Keys *)

  let configure_keys i =
    let file = String.lowercase Key.module_name ^ ".ml" in
    info "%a %s" blue "Generating:"  file;
    with_file (Info.root i / file) @@ fun fmt ->
    Codegen.append fmt "(* %s *)" (generated_header ()) ;
    Codegen.newline fmt;
    let bootvars = Info.keys i in
    Fmt.pf fmt "@[<v>%a@]@."
      (Fmt.iter Key.Set.iter @@ Key.emit) bootvars ;
    Codegen.append fmt "let runtime_keys = %a"
      Fmt.(Dump.list (fmt "%s_t"))
      (List.map Key.ocaml_name @@
       Key.Set.elements @@ Key.filter_stage ~stage:`Run bootvars);
    Codegen.newline fmt ;
    R.ok ()

  let clean_keys i =
    let file = String.lowercase Key.module_name ^ ".ml" in
    R.ok @@ remove (Info.root i / file)

  let key_name = "bootvar"

  let keys (argv : argv impl) = impl @@ object
      inherit base_configurable
      method ty = job
      method name = key_name
      method module_name = Key.module_name
      method configure = configure_keys
      method clean = clean_keys
      method libraries = Key.pure [ "functoria.runtime" ]
      method packages = Key.pure [ "functoria" ]
      method dependencies = [ hide argv ]
      method connect info modname = function
        | [ argv ] ->
          Fmt.strf
            "return (Functoria_runtime.with_argv %s.runtime_keys %S %s)"
            modname (Info.name info) argv
        | _ -> failwith "The keys connect should receive exactly one argument."
    end

  (** Module emiting a file containing all the build information. *)

  type info = Info
  let info = Type Info

  let pp_libraries fmt l =
    Fmt.pf fmt "StringSet.of_list [@ %a]"
      Fmt.(iter ~sep:(unit ";@ ") StringSet.iter @@ fmt "%S") l

  let pp_packages fmt l =
    Fmt.pf fmt
      "@ List.fold_left (fun set (k,v) -> StringMap.add k v set) StringMap.empty \
       [@ %a]"
      Fmt.(iter ~sep:(unit ";@ ") StringSet.iter @@
        (fun fmt x -> pf fmt "%S, \"%%{%s:version}%%\"" x x))
      l

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

      method libraries = Key.pure ["functoria.runtime"]
      method packages = Key.pure ["functoria"]

      method connect _ modname _ =
        Fmt.strf "return (`Ok %s.info)" modname

      method clean i =
        let file = Info.root i / (String.lowercase gen_file_name ^ ".ml") in
        remove file ;
        remove (file ^".in") ;
        R.ok ()

      method configure i =
        let filename = String.lowercase gen_file_name ^ ".ml" in
        let file = Info.root i / filename in
        Misc.info "%a %s" blue "Generating: " filename ;
        let f fmt =
          Fmt.pf fmt "@[<v 2>let info = %a@]" pp_dump_info i
        in
        with_file (file^".in") f ;
        command ~redirect:false "opam config subst %s" filename
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
    | G.If cond -> Key.deps cond
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
  let name c id =
    let base = Name.ocamlify c#name in
    Name.of_key (Fmt.strf "%s%i" base id) ~base

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
  let module_name c id args =
    let base = c#module_name in
    if args = [] then base
    else
      let base = try String.(sub base 0 @@ index base '.') with _ -> base in
      let base = Name.ocamlify base in
      Name.of_key (Fmt.strf "%s%i" base id) ~base

  let find_bootvar g =
    let p = function
      | G.Impl c -> c#name = Devices.key_name
      | _ -> false
    in match G.find_all g p with
    | [ x ] -> x
    | _ -> invalid_arg
        "Functoria.find_bootvar: There should be only one bootvar device."

  let configure info g =
    let tbl = G.Tbl.create 17 in
    let f v = match G.explode g v with
      | `App _ | `If _ -> assert false
      | `Impl (c, `Args args, `Deps _) ->
        let modname = module_name c (G.hash v) args in
        G.Tbl.add tbl v modname ;
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
    G.fold f g @@ R.ok () >>| fun () ->
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
        let ident = name c (G.hash v) in
        let modname = G.Tbl.find modtbl v in
        G.Tbl.add tbl v ident ;
        let names = List.map (G.Tbl.find tbl) (args @ deps) in
        Codegen.append_main "%a"
          emit_connect (error, ident, names, c#connect info modname)
    in
    G.fold (fun v () -> f v) g () ;
    let main_name = G.Tbl.find tbl @@ G.find_root g in
    let bootvar_name = G.Tbl.find tbl @@ find_bootvar g in
    Codegen.append_main
      "let () = run (%s () >>= fun _ -> %s ())"
      bootvar_name main_name ;
    ()

  let configure_and_connect info error g =
    configure info g >>| fun modtbl ->
    connect modtbl info error g

  let clean i g =
    let f v = match G.explode g v with
      | `Impl (c,_,_) -> c#clean i
      | _ -> R.ok ()
    in
    let f v res = res >>= fun () -> f v in
    G.fold f g @@ R.ok ()

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
      name root main_dev =
    let jobs = G.create main_dev in
    let libraries = Key.pure @@ StringSet.of_list libraries in
    let packages = Key.pure @@ StringSet.of_list packages in
    let keys = Key.Set.(union (of_list keys) (Engine.switching_keys jobs))
    in
    { libraries ; packages ; keys ; name ; root ; jobs }

  let eval { name = n ; root ; packages ; libraries ; keys ; jobs } =
    let e = G.eval jobs in
    let open Key in
    let packages = pure StringSet.union $ packages $ Engine.packages e in
    let libraries = pure StringSet.union $ libraries $ Engine.libraries e in
    let keys = Key.Set.union keys @@ Engine.keys e in
    let di =
      pure (fun libraries packages ->
        Info.create ~libraries ~packages ~keys ~name:n ~root)
      $ libraries
      $ packages
    in
    e, with_deps ~keys di

  (** Extract all the keys directly.
      Useful to pre-resolve the keys provided by the specialized DSL. *)
  let extract_keys impl =
    Engine.keys @@ G.create impl

  let name t = t.name
  let keys t = t.keys

  let gen_pp pp ~partial fmt t =
    pp fmt @@ G.eval ~partial t.jobs

  let pp = gen_pp G.pp
  let pp_dot = gen_pp G.pp_dot
end

module type SPECIALIZED = sig

  val prelude : string

  val name : string

  val version : string

  val driver_error : string -> string

  val argv : Devices.argv impl

  val config : job impl list -> job impl

end

module Make (P:SPECIALIZED) = struct

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
    let main_dev = P.config (Devices.keys P.argv :: jobs) in
    let c =
      Config.make ~keys ~libraries ~packages name root main_dev
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
            begin
              if no_depext then Ok ()
              else begin
                if command_exists "opam-depext"
                then Ok (info "opam depext is installed.")
                else opam "install" ["depext"]
              end >>= fun () -> opam ~yes:false "depext" ps
            end >>= fun () ->
            opam "install" ps
          ) else version_error ()
        | _ -> version_error ()
      )
    else error "OPAM is not installed."

  let configure_main i jobs =
    info "%a main.ml" blue "Generating:";
    Codegen.set_main_ml (Info.root i / "main.ml");
    Codegen.append_main "(* %s *)" (generated_header ());
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
    remove (Info.root i / "main.ml")

  let configure ~no_opam ~no_depext ~no_opam_version i jobs =
    info "%a %s" blue "Using configuration:"  (get_config_file ());
    in_dir (Info.root i) (fun () ->
      begin if no_opam
        then Ok ()
        else configure_opam ~no_depext ~no_opam_version i
      end >>= fun () ->
      configure_main i jobs
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

  let clean i jobs =
    info "%a %s" blue "Clean:"  (get_config_file ());
    let root = Info.root i in
    in_dir root (fun () ->
      clean_main i jobs >>= fun () ->
      command "rm -rf %s/_build" root >>= fun () ->
      command "rm -rf log %s/main.native.o %s/main.native %s/*~"
        root root root ;
    )

  let describe g ~dotcmd ~dot ~eval file =
    let f fmt =
      Config.(if dot then pp_dot else pp)
        ~partial:(not eval) fmt g
    in
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
    include P

    let base_keys =
      Key.term ~stage:`Configure @@ Config.extract_keys (P.config [])

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
      Key.term ~stage:`Configure @@ Config.keys t

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

  let launch () =
    let module M = Functoria_tool.Make(C) in
    ()

end


module type S = module type of Dsl
module type KEY = module type of Dsl.Key
