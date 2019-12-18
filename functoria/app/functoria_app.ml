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
include Misc

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

  let file = Fpath.(v (String.Ascii.lowercase Key.module_name) + "ml")

  let configure i =
    Log.info (fun m -> m "Generating: %a" Fpath.pp file);
    with_output file
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

  let clean _i = Bos.OS.Path.delete file

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

let pp_libraries fmt l =
  Fmt.pf fmt "[@ %a]"
    Fmt.(iter ~sep:(unit ";@ ") List.iter @@ fmt "%S") l

let pp_packages fmt l =
  Fmt.pf fmt "[@ %a]"
    Fmt.(iter ~sep:(unit ";@ ") List.iter @@
         (fun fmt x -> pf fmt "%S, \"%%{%s:version}%%\"" x x)
        ) l

let pp_dump_pkgs module_name fmt (name, pkg, libs) =
  Fmt.pf fmt
    "%s.{@ name = %S;@ \
     @[<v 2>packages = %a@]@ ;@ @[<v 2>libraries = %a@]@ }"
    module_name name
    pp_packages (String.Set.elements pkg)
    pp_libraries (String.Set.elements libs)

let app_info ?(type_modname="Functoria_info")  ?(gen_modname="Info_gen") () =
  impl @@ object
    inherit base_configurable
    method ty = info
    method name = "info"
    val file = Fpath.(v (String.Ascii.lowercase gen_modname) + "ml")
    method module_name = gen_modname
    method !packages = Key.pure [package "functoria-runtime"]
    method !connect _ modname _ = Fmt.strf "return %s.info" modname

    method !clean _i =
      Bos.OS.Path.delete file >>= fun () ->
      Bos.OS.Path.delete Fpath.(file + "in")

    method !configure _i = Ok ()

    method !build i =
      Log.info (fun m -> m "Generating: %a" Fpath.pp file);
      (* this used to call 'opam list --rec ..', but that leads to
         non-reproducibility, since this uses the opam CUDF solver which
         drops some packages (which are in the repositories configured for the
         switch), see https://github.com/mirage/functoria/pull/189 for further
         discussion on this before changing the code below.  *)
      let rec opam_deps args collected =
        Log.debug (fun m -> m
                      "opam_deps %d args %d collected\nargs: %a\ncollected: %a"
                      (String.Set.cardinal args) (String.Set.cardinal collected)
                      (String.Set.pp ~sep:(Fmt.unit ",") Fmt.string) args
                      (String.Set.pp ~sep:(Fmt.unit ",") Fmt.string) collected);
        if String.Set.is_empty args then Ok collected
        else
          let pkgs = String.concat ~sep:"," (String.Set.elements args) in
          let cmd =
            Bos.Cmd.(v "opam" % "list" % "--installed" % "-s" % "--color=never" % "--depopts" % "--required-by" % pkgs)
          in
          (Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_lines) >>= fun (rdeps, _) ->
          let reqd = String.Set.of_list rdeps in
          let collected' = String.Set.union collected reqd in
          opam_deps (String.Set.diff collected' collected) collected'
      in
      opam_deps (String.Set.of_list (Info.package_names i)) String.Set.empty >>= fun opam ->
      let ocl = String.Set.of_list (Info.libraries i)
      in
      Bos.OS.File.writef Fpath.(file + "in")
        "@[<v 2>let info = %a@]" (pp_dump_pkgs type_modname) (Info.name i, opam, ocl) >>= fun () ->
      Bos.OS.Cmd.run Bos.Cmd.(v "opam" % "config" % "subst" % p file)
  end

module Engine = struct

  let if_context =
    let open Key_graph in
    Key_graph.collect (module Key.Set) @@ function
    | If cond      -> Key.deps cond
    | App | Impl _ -> Key.Set.empty

  let keys =
    let open Key_graph in
    Key_graph.collect (module Key.Set) @@ function
    | Impl c  -> Key.Set.of_list c#keys
    | If cond -> Key.deps cond
    | App     -> Key.Set.empty

  module M = struct
    type t = package list Key.value
    let union x y = Key.(pure List.append $ x $ y)
    let empty = Key.pure []
  end

  let packages =
    let open Key_graph in
    Key_graph.collect (module M) @@ function
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
      Fmt.(list (parens @@ of_to_string @@ Key_graph.Tbl.find tbl))
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
    let open Key_graph in
    let p = function
      | Impl c     -> c#name = name
      | App | If _ -> false
    in
    match Key_graph.find_all g p with
    | []  -> invalid_arg "Functoria.find_device: no device"
    | [x] -> x
    | _   -> invalid_arg "Functoria.find_device: too many devices."

  let build info (_init, job) =
    let f v = match Key_graph.explode job v with
      | `App _ | `If _ -> R.ok ()
      | `Impl (c, _, _) -> c#build info
    in
    let f v res = res >>= fun () -> f v in
    Key_graph.fold f job @@ R.ok ()

  let configure info (_init, job) =
    let tbl = Key_graph.Tbl.create 17 in
    let f v = match Key_graph.explode job v with
      | `App _ | `If _ -> assert false
      | `Impl (c, `Args args, `Deps _) ->
        let modname = module_name c (Key_graph.hash v) args in
        Key_graph.Tbl.add tbl v modname;
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
    Key_graph.fold f job @@ R.ok () >>| fun () ->
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
    let tbl = Key_graph.Tbl.create 17 in
    let f v = match Key_graph.explode job v with
      | `App _ | `If _ -> assert false
      | `Impl (c, `Args args, `Deps deps) ->
        let ident = name c (Key_graph.hash v) in
        let modname = Key_graph.Tbl.find modtbl v in
        Key_graph.Tbl.add tbl v ident;
        let names = List.map (Key_graph.Tbl.find tbl) (args @ deps) in
        Codegen.append_main "%a"
          emit_connect (ident, names, c#connect info modname)
    in
    Key_graph.fold (fun v () -> f v) job ();
    let main_name = Key_graph.Tbl.find tbl @@ Key_graph.find_root job in
    let init_names =
      List.map (fun name -> Key_graph.Tbl.find tbl @@ find_device info job name) init
    in
    emit_run init_names main_name;
    ()

  let configure_and_connect info g =
    configure info g >>| fun modtbl ->
    connect modtbl info g

  let clean i g =
    let f v = match Key_graph.explode g v with
      | `Impl (c,_,_) -> c#clean i
      | _ -> R.ok ()
    in
    let f v res = res >>= fun () -> f v in
    Key_graph.fold f g @@ R.ok ()

end

module Config = struct

  type t = {
    name     : string;
    build_dir: Fpath.t;
    packages : package list Key.value;
    keys     : Key.Set.t;
    init     : job impl list;
    jobs     : Key_graph.t;
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

  let make ?(keys=[]) ?(packages=[]) ?(init=[]) name build_dir main_dev =
    let name = Name.ocamlify name in
    let jobs = Key_graph.create main_dev in
    let packages = Key.pure @@ packages in
    let keys = Key.Set.(union (of_list keys) (get_if_context jobs)) in
    { packages; keys; name; build_dir; init; jobs }

  let eval ~partial context
      { name = n; build_dir; packages; keys; jobs; init }
    =
    let e = Key_graph.eval ~partial ~context jobs in
    let packages = Key.(pure List.append $ packages $ Engine.packages e) in
    let keys = Key.Set.elements (Key.Set.union keys @@ Engine.keys e) in
    Key.(pure (fun packages _ context ->
        ((init, e),
         Info.create
           ~packages
           ~keys ~context ~name:n ~build_dir))
         $ packages
         $ of_deps (Set.of_list keys))

  (* Extract all the keys directly. Useful to pre-resolve the keys
     provided by the specialized DSL. *)
  let extract_keys impl =
    Engine.keys @@ Key_graph.create impl

  let keys t = t.keys

  let gen_pp pp fmt jobs =
    pp fmt @@ Key_graph.simplify jobs

  let pp = gen_pp Key_graph.pp
  let pp_dot = gen_pp Key_graph.pp_dot

end

(** Cached configuration in [.mirage.config].
    Currently, we cache Sys.argv directly
*)
module Cache : sig
  open Cmdliner
  val save : argv:string array -> Fpath.t -> (unit, [> Rresult.R.msg ]) result
  val clean : Fpath.t -> (unit, [> Rresult.R.msg ]) result
  val get_context : Fpath.t -> context Term.t ->
    [> `Error of bool * string | `Ok of context option ]
  val get_output: Fpath.t -> [> `Error of bool * string | `Ok of string option ]
  val require :
    [< `Error of bool * string | `Ok of context option ] -> context Term.ret
  val merge :
    cache:[< `Error of bool * string | `Ok of context option ] ->
    context -> context
  val present :
    [< `Error of bool * string | `Ok of context option ] -> bool
end = struct
  let filename root =
    Fpath.(root / ".mirage" + "config")

  let save ~argv root =
    let file = filename root in
    Log.info (fun m -> m "Preserving arguments in %a" Fpath.pp file);
    let args = List.tl (Array.to_list argv) in (* Only keep args *)
    let args = List.map String.Ascii.escape args in
    let args = String.concat ~sep:"\n" args in
    Bos.OS.File.write file args

  let clean root =
    Bos.OS.File.delete (filename root)

  let read root =
    Log.info (fun l -> l "reading cache");
    match Bos.OS.File.read (filename root) with
    | Error _ -> None
    | Ok args ->
      let contents = Array.of_list @@ String.cuts ~sep:"\n" args in
      let contents =
        Array.map (fun x -> match String.Ascii.unescape x with
            | Some s -> s
            | None   -> failwith "cannot parse cached context"
          ) contents
      in
      Some contents

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

  let get_output root =
    match get_context root Cli.output with
    | `Ok (Some None) -> `Ok None
    | `Ok (Some x)    -> `Ok x
    | `Ok None        -> `Ok None
    | `Error e        -> `Error e

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
  val packages: package list
  val ignore_dirs: string list
  val version: string
  val create: job impl list -> job impl
end

module type DSL = sig
  type 'a typ = 'a Functoria.typ =
    | Type    : 'a -> 'a typ
    | Function: 'b typ * 'c typ -> ('b -> 'c) typ
  val typ: 'a -> 'a typ
  val (@->): 'a typ -> 'b typ -> ('a -> 'b) typ
  type job = Functoria.job
  val job: job typ
  type 'a impl = 'a Functoria.impl
  val ($): ('a -> 'b) impl -> 'a impl -> 'b impl
  type abstract_impl = Functoria.abstract_impl
  val abstract: _ impl -> abstract_impl
  type key = Functoria.key
  type context = Functoria.context
  type 'a value = 'a Functoria.value
  val if_impl: bool value -> 'a impl -> 'a impl -> 'a impl
  val match_impl: 'b value -> default:'a impl -> ('b * 'a impl) list ->  'a impl
  type package = Functoria.package
  val package :
    ?build:bool ->
    ?sublibs:string list ->
    ?ocamlfind:string list ->
    ?min:string ->
    ?max:string ->
    ?pin:string ->
    string -> package
  val foreign:
    ?packages:package list ->
    ?keys:key list ->
    ?deps:abstract_impl list ->
    string -> 'a typ -> 'a impl
  class type ['ty] configurable = object
    method ty: 'ty typ
    method name: string
    method module_name: string
    method packages: package list value
    method connect: Info.t -> string -> string list -> string
    method configure: Info.t -> (unit, Rresult.R.msg) result
    method build: Info.t -> (unit, Rresult.R.msg) result
    method clean: Info.t -> (unit, Rresult.R.msg) result
    method keys: key list
    method deps: abstract_impl list
  end
  val impl: 'a configurable -> 'a impl
  class base_configurable: object
    method packages: package list value
    method keys: key list
    method connect: Info.t -> string -> string list -> string
    method configure: Info.t -> (unit, Rresult.R.msg) result
    method build: Info.t -> (unit, Rresult.R.msg) result
    method clean: Info.t -> (unit, Rresult.R.msg) result
    method deps: abstract_impl list
  end
  class ['a] foreign:
    ?packages:package list ->
    ?keys:key list ->
    ?deps:abstract_impl list ->
    string -> 'a typ -> ['a] configurable
end

module Make (P: S) = struct

  (* GLOBAL STATE *)

  (* this needs to be set-up beforce any calls to {!register} *)
  let build_dir = ref None
  let default_init = [keys sys_argv]
  let config_file = ref Fpath.(v "config.ml")

  let init_global_state argv =
    build_dir := None;
    config_file := Fpath.(v "config.ml");
    ignore (Cmdliner.Term.eval_peek_opts ~argv Cli.setup_log);
    ignore (Cmdliner.Term.eval_peek_opts ~argv @@
            Cli.config_file (fun c -> config_file := c));
    ignore (Cmdliner.Term.eval_peek_opts ~argv @@
            Cli.build_dir (fun r ->
                let (_:bool) = R.get_ok @@ Bos.OS.Dir.create ~path:true r in
                build_dir := Some r))

  let get_project_root () = R.get_ok @@ Bos.OS.Dir.current ()

  let relativize ~root p =
    let p =  if Fpath.is_abs p then p else Fpath.(get_project_root () // p) in
    match Fpath.relativize ~root p with
    | Some p -> p
    | None -> Fmt.failwith "relativize: root=%a %a" Fpath.pp root Fpath.pp p

  let get_relative_source_dir () =
    let dir = Fpath.parent !config_file in
    let root = get_project_root () in
    relativize ~root dir

  let get_build_dir () =
    let dir = match !build_dir with
      | None -> get_relative_source_dir ()
      | Some p -> p
    in
    let dir =
      if Fpath.is_abs dir then dir
      else Fpath.(get_project_root () // dir)
    in
    let root = get_project_root () in
    let rel = relativize ~root dir in
    match Fpath.segs rel with
    | ".." :: _ -> failwith "--build-dir should be a sub-directory."
    | _ -> dir

  let auto_generated =
    ";; auto-generated by 'mirage configure -- remove these comments to\n\
     ;; preserve the file after a `mirage clean`"

  let can_overwrite file =
    Bos.OS.File.exists file >>= function
    | false -> Ok true
    | true ->
      if Fpath.basename file = "dune-project" then
        Bos.OS.File.read_lines file >>| function
        | [] -> true
        | _ :: x :: y :: _ -> x ^ "\n" ^ y = auto_generated
        | _ -> false
      else
        Bos.OS.File.read_lines file >>| function
        | [] | [_] -> true
        | x :: y :: _ -> x ^ "\n" ^ y = auto_generated

  (* STAGE 1 *)

  let generate ~file ~contents =
    can_overwrite file >>= function
    | false -> Ok ()
    | true ->
      Bos.OS.File.delete file >>= fun () ->
      Bos.OS.File.write file contents

  let list_files dir =
    Bos.OS.Path.matches ~dotfiles:true Fpath.(dir / "$(file)") >>= fun l ->
    List.fold_left (fun acc src ->
        acc >>= fun acc ->
        match Fpath.basename src with
        | "_build" | "main.ml" | "key_gen.ml" -> Ok acc
        | s when Filename.extension s = ".exe" -> Ok acc
        | _ -> Ok (src :: acc)
      ) (Ok []) l

  (* Generate a `dune.config` file in the build directory. *)
  let generate_dune_config ~project_root ~source_dir () =
    let file = Fpath.v "dune.config" in
    let pkgs = match P.packages with
      | []   -> ""
      | pkgs ->
        let pkgs =
          List.fold_left (fun acc pkg ->
              String.Set.union pkg.ocamlfind acc
            ) String.Set.empty pkgs
          |> String.Set.elements
        in
        String.concat ~sep:" " pkgs
    in
    let copy_rule file = match !build_dir with
      | None -> ""
      | Some root ->
        let root = Fpath.(project_root // root) in
        let src = relativize ~root file in
        let file = Fpath.basename file in
        Fmt.strf "(rule (copy %a %s))\n\n" Fpath.pp src file
    in
    list_files Fpath.(project_root // source_dir) >>= fun files ->
    let copy_rules = List.map copy_rule files in
    let config_file = Fpath.(basename (rem_ext !config_file)) in
    let contents =
      Fmt.strf
        {|%s

%a(executable
  (name config)
  (modules %s)
  (libraries %s))
|}
        auto_generated Fmt.(list ~sep:(unit "") string) copy_rules
        config_file pkgs
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
      Fmt.strf "%s

(include dune.config)\n\n(include dune.build)\n"
        auto_generated
    in
    generate ~file ~contents

  (* Generate a `dune-project` file at the project root. *)
  let generate_dune_project ~project_root =
    let file = Fpath.(project_root / "dune-project") in
    let contents = Fmt.strf "(lang dune 1.1)\n%s\n" auto_generated in
    generate ~file ~contents

  (* Generate the configuration files in the the build directory *)
  let generate_configuration_files
      ~project_root ~source_dir ~build_dir ~config_file
    =
    Log.info (fun m -> m "Compiling: %a" Fpath.pp config_file);
    Log.info (fun m -> m "Project root: %a" Fpath.pp project_root);
    Log.info (fun m -> m "Build dir: %a" Fpath.pp build_dir);
    ( match Bos.OS.File.must_exist config_file with
      | Ok _ -> Ok ()
      | Error _ ->
        R.error_msgf "configuration file %a missing" Fpath.pp config_file
    ) >>= fun () ->
    generate_dune_project ~project_root >>= fun () ->
    Bos.OS.Dir.with_current build_dir (fun () ->
        generate_dune_config ~project_root ~source_dir () >>= fun () ->
        generate_empty_dune_build () >>= fun () ->
        generate_dune ()
      ) () >>= fun result ->
    result

  (* Compile the configuration files and execute it. *)
  let build_and_execute ?help_ppf ?err_ppf argv =
    let build_dir = get_build_dir () in
    let config_file = !config_file in
    let project_root = get_project_root () in
    let source_dir = get_relative_source_dir () in
    generate_configuration_files
      ~project_root ~source_dir ~build_dir ~config_file
    >>= fun () ->
    let args = Bos.Cmd.of_list (List.tl (Array.to_list argv)) in
    let target_dir = relativize ~root:project_root build_dir in
    let command =
      Bos.Cmd.(v "dune" % "exec"
               % "--root" % p project_root
               % "--" % p Fpath.(target_dir / "config.exe") %% args)
    in
    match help_ppf, err_ppf with
    | None, None -> Bos.OS.Cmd.run command
    | _, _ -> (
        let dune_exec_cmd = Bos.OS.Cmd.run_out command in
        let command_result = Bos.OS.Cmd.to_string dune_exec_cmd in
        match command_result, help_ppf, err_ppf with
        | Ok output, Some help_ppf, _ -> Format.fprintf help_ppf "%s" output; Ok ()
        | Error `Msg err, _, Some err_ppf -> Format.fprintf err_ppf "%s" err; Ok ()
        | _ -> Ok ()
      )

  let exit_err = function
    | Ok v -> v
    | Error (`Msg m) ->
      R.pp_msg Format.std_formatter (`Msg m) ;
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
        ~configure:(Term.pure ())
        ~describe:(Term.pure ())
        ~build:(Term.pure ())
        ~clean:(Term.pure ())
        ~help:base_context
        argv
    in
    match result with
    | `Ok Cli.Help -> ()
    | `Error _
    | `Ok (Cli.Configure _ | Cli.Describe _ | Cli.Build _ | Cli.Clean _) ->
      exit_err (Error error)
    | `Version
    | `Help -> ()

  let run_with_argv ?help_ppf ?err_ppf argv =
    (* 1. Pre-parse the arguments set the log level, config file
       and root directory. *)
    init_global_state argv;
    (* 2. Build the config from the config file. *)
    (* There are three possible outcomes:
         1. the config file is found and built successfully
         2. no config file is specified
         3. an attempt is made to access the base keys at this point.
            when they weren't loaded *)

    match build_and_execute ?help_ppf ?err_ppf argv with
    | Error (`Invalid_config_ml err) -> exit_err (Error (`Msg err))
    | Error (`Msg _ as err) ->
      handle_parse_args_no_config ?help_ppf ?err_ppf err argv
    | Ok () -> ()

  let run () =
    run_with_argv Sys.argv

  (* STAGE 2 *)

  let src = Logs.Src.create (P.name^"-configure") ~doc:"functoria generated"
  module Log = (val Logs.src_log src : Logs.LOG)

  module Config' = struct
    let pp_info (f:('a, Format.formatter, unit) format -> 'a) level info =
      let verbose = Logs.level () >= level in
      f "@[<v>%a@]" (Info.pp verbose) info

    let eval_cached ~partial cached_context t =
      let f c =
        let info = Config.eval ~partial c t in
        let keys = Key.deps info in
        let term = Key.context ~stage:`Configure ~with_required:false keys in
        match Cache.get_context t.Config.build_dir term with
        | `Ok (Some c) -> `Ok (Key.eval c info c)
        | `Ok None     -> let c = Key.empty_context in`Ok (Key.eval c info c)
        | `Error _ | `Help _ as err -> err
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
      let update_output (r, i) = r, Info.with_output i o in
      Cmdliner.Term.(app (const update_output) term)
    | _ -> term

  let exit_err = function
    | Ok v -> v
    | Error (`Msg m) ->
      R.pp_msg Format.std_formatter (`Msg m) ;
      print_newline ();
      flush_all ();
      exit 1

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

  let with_output i = function
    | None   -> i
    | Some o -> Info.with_output i o

  let configure_main ~argv i jobs =
    let main = match Info.output i with None -> "main" | Some f -> f in
    let file = main ^ ".ml" in
    Log.info (fun m -> m "Generating: %s" file);
    Codegen.set_main_ml file;
    Codegen.append_main "(* %s *)" (Codegen.generated_header ());
    Codegen.newline_main ();
    Codegen.append_main "%a" Fmt.text  P.prelude;
    Codegen.newline_main ();
    Codegen.append_main "let _ = Printexc.record_backtrace true";
    Codegen.newline_main ();
    Cache.save ~argv (Info.build_dir i) >>= fun () ->
    Engine.configure_and_connect i jobs >>| fun () ->
    Codegen.newline_main ()

  let clean_main i jobs =
    Engine.clean i jobs >>= fun () ->
    Bos.OS.File.delete Fpath.(v "main.ml")

  let configure ~argv i jobs =
    let source_dir = get_relative_source_dir () in
    Log.debug (fun l -> l "source-dir=%a" Fpath.pp source_dir);
    Log.info (fun m -> m "Configuration: %a" Fpath.pp !config_file);
    Log.info (fun m -> m "Output       : %a" Fmt.(option string) (Info.output i));
    Log.info (fun m -> m "Build-dir    : %a" Fpath.pp (Info.build_dir i));
    with_current
      (Info.build_dir i)
      (fun () -> configure_main ~argv i jobs)
      "configure"

  let build i jobs =
    Log.info (fun m -> m "Building: %a" Fpath.pp !config_file);
    with_current
      (Info.build_dir i)
      (fun () -> Engine.build i jobs)
      "build"

  let clean i (_init, job) =
    Log.info (fun m -> m "Cleaning: %a" Fpath.pp !config_file);
    let clean_file file =
      can_overwrite file >>= function
      | false -> Ok ()
      | true -> Bos.OS.File.delete file
    in
    clean_file Fpath.(v "dune-project") >>= fun () ->
    Cache.clean (Info.build_dir i) >>= fun () ->
    (match Sys.getenv "INSIDE_FUNCTORIA_TESTS" with
     | "1" -> Ok ()
     | exception Not_found -> Bos.OS.Dir.delete ~recurse:true Fpath.(v "_build")
     | _ -> Bos.OS.Dir.delete ~recurse:true Fpath.(v "_build")
    ) >>= fun () ->
    with_current
      (Info.build_dir i)
      (fun () ->
         clean_main i job >>= fun () ->
         clean_file Fpath.(v "dune") >>= fun () ->
         clean_file Fpath.(v "dune.config") >>= fun () ->
         clean_file Fpath.(v "dune.build") >>= fun () ->
         Bos.OS.File.delete Fpath.(v ".merlin"))
      "clean"

  let handle_parse_args_result argv = function
    | `Error _ -> exit 1
    | `Ok Cli.Help -> ()
    | `Ok (Cli.Configure { result = (jobs, info); output }) ->
      let info = with_output info output in
      Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
      exit_err (configure ~argv info jobs)
    | `Ok (Cli.Build (jobs, info)) ->
      Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
      exit_err (build info jobs)
    | `Ok (Cli.Describe { result = (jobs, info); dotcmd; dot; output }) ->
      Config'.pp_info Fmt.(pf stdout) (Some Logs.Info) info;
      R.error_msg_to_invalid_arg (describe info jobs ~dotcmd ~dot ~output)
    | `Ok (Cli.Clean (jobs, info)) ->
      Log.info (fun m -> Config'.pp_info m (Some Logs.Debug) info);
      exit_err (clean info jobs)
    | `Version
    | `Help -> ()

  let run_configure_with_argv argv config =
  (*   whether to fully evaluate the graph *)
    let full_eval = Cli.read_full_eval argv in
  (* Consider only the 'if' keys. *)
    let if_term =
      let if_keys = Config.keys config in
      Key.context ~stage:`Configure ~with_required:false if_keys
    in

    let context = match Cmdliner.Term.eval_peek_opts ~argv if_term with
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
      let partial = match full_eval with
        | Some true  -> false
        | Some false -> true
        | None -> not (Cache.present cached_context)
      in
      Config'.eval ~with_required:false ~partial context config
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
      (Cli.parse_args ~name:P.name ~version:P.version
          ~configure
          ~describe
          ~build
          ~clean
          ~help
          argv)

  let register ?packages ?keys ?(init=default_init) name jobs =
    (* 1. Pre-parse the arguments set the log level, config file
       and root directory. *)
    init_global_state Sys.argv;
    let build_dir = get_build_dir () in
    let main_dev = P.create (init @ jobs) in
    let c = Config.make ?keys ?packages ~init name build_dir main_dev in
    run_configure_with_argv Sys.argv c

end

module Cli = Cli
