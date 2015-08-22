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
module Key = Functoria_key



module Info = struct

  type t = {
    name: string;
    root: string;
    keys: Key.Set.t;
    libraries : StringSet.t;
    packages : StringSet.t;
  }

  let name t = t.name
  let root t = t.root
  let libraries t = t.libraries
  let packages t = t.packages
  let keys t = t.keys

end

type _ typ =
  | Type: 'a -> 'a typ
  | Function: 'a typ * 'b typ -> ('a -> 'b) typ

let (@->) f t =
  Function (f, t)

let typ ty = Type ty


type job = JOB
let job = Type JOB

module rec Typ : sig
  class type ['ty] configurable = object
    method ty : 'ty typ
    method name: string
    method module_name: string
    method packages: string list
    method libraries: string list
    method keys: Key.t list
    method connect : Info.t -> string -> string list -> string
    method configure: Info.t -> unit
    method clean: unit
    method dependencies: job Typ.impl list
  end

  type _ impl =
    | Impl: 'ty configurable -> 'ty impl (* base implementation *)
    | App: ('a, 'b) app -> 'b impl   (* functor application *)
    | If : bool Key.value * 'a impl * 'a impl -> 'a impl

  and ('a, 'b) app = {
    f: ('a -> 'b) impl;  (* functor *)
    x: 'a impl;          (* parameter *)
  }

end = Typ
include Typ


let ($) f x =
  App { f; x }

let impl x = Impl x

let switch b x y = If(b,x,y)

class base_configurable = object
  method libraries : string list = []
  method packages : string list = []
  method keys : Key.t list = []
  method connect (_:Info.t) (_:string) l =
    Printf.sprintf "return (`Ok (%s))" (String.concat ", " l)
  method configure (_ : Info.t) = ()
  method clean = ()
  method dependencies : job impl list = []
end

(** Decision trees *)
module DTree = struct

  type +'a t =
    | Leaf : 'a -> 'a t
    | If : bool Key.value * 'a t * 'a t -> 'a t

  let rec push_app' : type a. a impl -> a impl * bool  = function
    | App {f = If (b, f1, f2) ;x} -> switch b (f1$x) (f2$x), true
    | App {f ; x = If(b, x1, x2)} -> switch b (f$x1) (f$x2), true
    | App {f ; x } ->
      let f, bf = push_app' f and x, bx = push_app' x in
      let b = bf || bx in
      if b then fst @@ push_app' (f $ x), true else f $ x, false
    | If (b, x, y) ->
      let x, bx = push_app' x and y, by = push_app' y in
      switch b x y, bx || by
    | Impl _ as f -> f, false

  let push_app i = fst @@ push_app' i

  let rec to_tree_internal : type a. a impl -> a impl t = function
    | If (b, x, y) -> If (b, to_tree_internal x, to_tree_internal y)
    | t -> Leaf t

  let to_tree x = to_tree_internal (push_app x)

  let rec map f = function
    | Leaf x -> Leaf (f x)
    | If (b, x, y) -> If (b, map f x, map f y)

  let rec to_list f = function
    | Leaf x -> f x
    | If (_, x, y) -> to_list f x @ to_list f y

  let rec keys = function
    | Leaf _ -> Key.Set.empty
    | If (b,x,y) ->
      Key.Set.union (Key.deps b) @@
      Key.Set.union (keys x) (keys y)

  let rec iter f = function
    | Leaf x -> f x
    | If (_,x,y) -> iter f x ; iter f y

  let rec partial_eval = function
    | Leaf _ as t -> t
    | If (b, x, y) as t -> match Key.peek b with
      | None -> t
      | Some true -> partial_eval x
      | Some false -> partial_eval y

  let rec eval = function
    | Leaf c -> c
    | If (b, x, y) ->
      if Key.eval b then eval x else eval y

end

module Modlist : sig
  type t
  type evaluated

  val of_impl : job impl -> t
  val eval : t list -> evaluated list

  val primary_keys : t list -> Key.Set.t

  val keys : evaluated list -> Key.Set.t
  val packages : evaluated list -> StringSet.t
  val libraries : evaluated list -> StringSet.t

  val configure_and_connect :
    Info.t -> (string -> string) -> evaluated list -> unit

  val clean : evaluated -> unit

  val pp : evaluated Fmt.t

end = struct

  type 'a modlist =
    | Mod  : _ configurable * 'a -> 'a modlist
    | List : _ configurable * 'a * 'a modlist list -> 'a modlist

  type t = T of t list modlist DTree.t
  type evaluated = E of evaluated list modlist
  let map_E f (E x) = f x

  let rec linearize
    : type ty . ty impl -> _ modlist
    = function
      | Impl m -> Mod (m,List.map of_impl m#dependencies)
      | If _ -> assert false
      | App { f ; x } ->
        let fuse = function
          | Mod (m, deps) -> List (m, deps, [linearize x])
          | List (m, deps, args) -> List (m, deps , args @ [linearize x])
        in fuse @@ linearize f

  and of_impl i =
    T (DTree.map linearize (DTree.to_tree i))

  let rec pp_modlist : 'a modlist Fmt.t = fun fmt -> function
    | Mod (d, _)        -> Fmt.string fmt d#module_name
    | List (f, _, args) ->
      Fmt.pf fmt "%s%a"
        f#module_name
        Fmt.(parens @@ list pp_modlist) args

  let pp fmt (E x) = pp_modlist fmt x

  let eval l =
    let tbl = Hashtbl.create 17 in
    let rec add_deps = function
      | Mod (m, deps) ->
        Mod (m, eval_list deps)
      | List (m, deps ,args) ->
        List (m, eval_list deps, List.map add_deps args)
    and eval (T m) =
      if Hashtbl.mem tbl m then Hashtbl.find tbl m
      else
        let m' = E (add_deps @@ DTree.eval m) in
        Hashtbl.add tbl m m' ; m'
    and eval_list l = List.map eval l
    in
    eval_list l

  (** Return a unique variable name holding the state of the given
      module construction. *)
  let rec name = function
    | Mod (d,_)           -> d#name
    | List (f,_,_) as t -> Name.of_key (module_name t) ~base:f#name

  (** Return a unique module name holding the implementation of the
      given module construction. *)
  and module_name = function
    | Mod (d,_)          -> d#module_name
    | List (f, x, args) ->
      let name = body (Mod (f,x) ) args in
      Name.of_key name ~base:"F"

  and body f args =
    functor_name f ^
      Fmt.(strf "%a" (list ~sep:nop @@ parens string)
        (List.map module_name args))

  and functor_name = function
    | Mod (d,_)      -> d#module_name
    | List (f,_,_) -> f#module_name



  type 'a mapper = {
    map: 'ty. 'ty configurable -> 'a ;
  }

  let concatmap (type t) (module M: Set.S with type t = t) f l =
    List.fold_left M.union M.empty @@ List.map f l

  let append (type t) (module M:Set.S with type t = t) a b =
    M.union a b

  let collect monoid map fm m =
    let flatmap f l = concatmap monoid f l in
    let (@) = append monoid in
    let rec collect = function
      | Mod (d, deps) -> fm.map d @ flatmap collect_dep deps
      | List (f, deps, args) ->
        fm.map f @ flatmap collect_dep deps @ flatmap collect args
    and collect_dep m = map collect m
    in flatmap (map collect) m

  let primary_keys m =
    List.fold_left
      (fun set (T x) -> Key.Set.union (DTree.keys x) set )
      Key.Set.empty
      m

  let collect_E monoid fm m = collect monoid map_E fm m
  let packages  =
    collect_E (module StringSet)
      { map = fun x -> StringSet.of_list x#packages }
  let libraries =
    collect_E (module StringSet)
      { map = fun x -> StringSet.of_list x#libraries }
  let keys      =
    collect_E (module Key.Set)
      { map = fun x -> Key.Set.of_list x#keys }



  let rec configure' tbl info m =
    let iname = name m in
    if not (Hashtbl.mem tbl iname) then begin
      Hashtbl.add tbl iname true;
      match m with
      | Mod (t, deps) ->
        t#configure info ;
        List.iter (configure tbl info) deps ;
      | List (f, deps, args) ->
        List.iter (configure tbl info) deps ;
        List.iter (configure' tbl info) args ;
        f#configure info ;
        let modname = module_name m in
        let body = body (Mod (f,deps)) args in
        Codegen.append_main "module %s = %s" modname body;
        Codegen.newline_main ();
    end
  and configure configured info (E m) = configure' configured info m

  let rec connect' tbl info error m =
    let iname = name m in
    if not (Hashtbl.mem tbl iname) then begin
      Hashtbl.add tbl iname true;
      let modname = module_name m in
      match m with
      | Mod (m, deps) ->
        List.iter (connect tbl info error) deps ;
        let names = List.map (map_E name) deps in
        Codegen.append_main "let %s () =" iname;
        Codegen.append_main "  %s" (m#connect info modname names);
        Codegen.newline_main ()
      | List (f, deps, args) ->
        List.iter (connect' tbl info error) args ;
        List.iter (connect tbl info error) deps ;
        let names =
          List.map name args @ List.map (map_E name) deps
        in
        Codegen.append_main "let %s () =" iname;
        List.iter (fun n ->
          Codegen.append_main "  %s () >>= function" n;
          Codegen.append_main "  | `Error e -> %s" (error n);
          Codegen.append_main "  | `Ok %s ->" n;
        ) names;
        Codegen.append_main "  %s" (f#connect info modname names);
        Codegen.newline_main ()
    end
  and connect tbl info error (E m) = connect' tbl info error m

  let configure_and_connect info error l =
    let configured = Hashtbl.create 31 in
    let connected = Hashtbl.create 31 in
    List.iter (fun m ->
      configure configured info m ;
      connect connected info error m)
      l



  type iter = { i : 'ty. 'ty configurable -> unit }

  let rec iter' fi m =
    match m with
    | Mod (b, deps) -> List.iter (iter fi) deps ; fi.i b
    | List (f, deps, args) ->
      List.iter (iter fi) deps ; List.iter (iter' fi) args ; fi.i f
  and iter fi (E m) = iter' fi m

  let clean t = iter { i = fun t -> t#clean } t

end

class ['ty] foreign
    ?(keys=[]) ?(libraries=[]) ?(packages=[])
    module_name ty
  : ['ty] configurable
  =
  let name = Name.of_key module_name ~base:"f" in
  object
    method ty = ty
    method name = name
    method module_name = module_name
    method keys = keys
    method libraries = libraries
    method packages = packages
    method connect _ m args =
      Printf.sprintf "%s.start %s" m (String.concat " " args)
    method clean = ()
    method configure _ = ()
    method dependencies = []
  end

let foreign ?keys ?libraries ?packages module_name ty =
  Impl (new foreign ?keys ?libraries ?packages module_name ty)

module Config = struct

  type t = {
    default_info : Info.t ;
    jobs : Modlist.t list ;
    custom : job configurable ;
  }

  let make
      ?(keys=[]) ?(libraries=[]) ?(packages=[])
      name root jobs init_dsl =
    let custom = init_dsl ~name ~root jobs in
    let keys = Key.Set.of_list keys in
    let libraries = StringSet.of_list libraries in
    let packages = StringSet.of_list packages in
    let jobs = List.map Modlist.of_impl @@ impl custom :: jobs in
    let default_info = {Info. keys ; libraries ; packages ; root ; name } in
    { default_info ; jobs ; custom }

  let eval { default_info = di ; jobs } =
    let e = Modlist.eval jobs in
    let libraries = StringSet.union di.libraries @@ Modlist.libraries e in
    let packages = StringSet.union di.packages @@ Modlist.packages e in
    let keys = Key.Set.union di.keys @@ Modlist.keys e in
    e, {di with keys ; libraries ; packages }

  let name t = t.default_info.name
  let root t = t.default_info.root
  let primary_keys t =
    Key.Set.union t.default_info.keys @@ Modlist.primary_keys t.jobs

end


module type PROJECT = sig

  val name : string

  val version : string

  val driver_error : string -> string

  val configurable :
    name:string -> root:string -> job impl list ->
    job configurable

end


module type CONFIG = sig
  module Project : PROJECT

  type t

  val register:
    ?keys:Key.t list -> ?libraries:string list -> ?packages:string list ->
    string -> job impl list -> unit

  val manage_opam_packages: bool -> unit
  val no_opam_version_check: bool -> unit
  val no_depext: bool -> unit

  val dummy_conf : t
  val load: string option -> (t, string) Rresult.result

  val primary_keys : t -> unit Cmdliner.Term.t
  val eval : t -> <
      build : unit;
      clean : unit;
      configure : unit;
      keys : unit Cmdliner.Term.t
    >
end

module Make (P:PROJECT) = struct
  module Project = P

  type t = Config.t

  let configuration = ref None
  let config_file = ref None

  let set_config_file f =
    config_file := Some f

  let get_config_file () =
    match !config_file with
    | None -> Sys.getcwd () / "config.ml"
    | Some f -> f
  let get_root () = Filename.dirname @@ get_config_file ()


  let dummy_conf =
    let name = P.name and root = get_root () in
    Config.make name root [] P.configurable

  let register ?(keys=[]) ?(libraries=[]) ?(packages=[]) name jobs =
    let root = get_root () in
    let c =
      Config.make ~keys ~libraries ~packages name root jobs P.configurable
    in
    configuration := Some c


  let registered () =
    match !configuration with
    | None   -> error "No configuration was registered."
    | Some t -> Ok t

  (** {2 Opam Management} *)

  let no_opam_version_check_ = ref false
  let no_opam_version_check b = no_opam_version_check_ := b

  let no_depext_ = ref false
  let no_depext b = no_depext_ := b

  let configure_opam t =
    info "Installing OPAM packages.";
    let ps = Info.packages t in
    if StringSet.is_empty ps then ()
    else
    if command_exists "opam" then
      if !no_opam_version_check_ then ()
      else (
        let opam_version = read_command "opam --version" in
        let version_error () =
          fail "Your version of OPAM (%s) is not recent enough. \
                Please update to (at least) 1.2: https://opam.ocaml.org/doc/Install.html \
                You can pass the `--no-opam-version-check` flag to force its use." opam_version
        in
        match split opam_version '.' with
        | major::minor::_ ->
          let major = try int_of_string major with Failure _ -> 0 in
          let minor = try int_of_string minor with Failure _ -> 0 in
          if (major, minor) >= (1, 2) then (
            let ps = StringSet.elements ps in
            if !no_depext_ then ()
            else (
              if command_exists "opam-depext" then
                info "opam depext is installed."
              else
                opam "install" ["depext"];
              opam ~yes:false "depext" ps;
            );
            opam "install" ps
          ) else version_error ()
        | _ -> version_error ()
      )
    else fail "OPAM is not installed."

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

  let manage_opam_packages_ = ref true
  let manage_opam_packages b = manage_opam_packages_ := b


  let configure_bootvar i =
    info "%a bootvar_gen.ml" blue "Generating:";
    with_file (Info.root i / "bootvar_gen.ml") @@ fun fmt ->
    Codegen.append fmt "(* %s *)" (generated_header P.name) ;
    Codegen.newline fmt;
    let bootvars = Key.Set.filter Key.is_runtime @@ Info.keys i
    in
    Key.Set.iter (Key.emit fmt) bootvars ;
    Codegen.newline fmt;
    Codegen.append fmt "let keys = %a"
      Fmt.(Dump.list (fmt "%s_t"))
      (List.map Key.name @@ Key.Set.elements bootvars);
    Codegen.newline fmt

  let clean_bootvar i =
    remove (Info.root i / "bootvar_gen.ml")


  let configure_main i jobs =
    info "%a main.ml" blue "Generating:";
    Codegen.set_main_ml (Info.root i / "main.ml");
    Codegen.append_main "(* %s *)" (generated_header P.name);
    Codegen.newline_main ();
    Codegen.append_main "open Lwt";
    Codegen.newline_main ();
    Codegen.append_main "let _ = Printexc.record_backtrace true";
    Codegen.newline_main ();
    Modlist.configure_and_connect i Project.driver_error jobs;
    Codegen.newline_main ();
    Codegen.append_main "let () = main ()";
    ()

  let clean_main i jobs =
    List.iter Modlist.clean jobs ;
    remove (Info.root i / "main.ml")

  let configure i jobs =
    info "%a %s" blue "Using configuration:"  (get_config_file ());
    info "%a@ [%a]"
      blue (Fmt.strf "%d Job%s:"
        (List.length jobs)
        (if List.length jobs = 1 then "" else "s"))
      (Fmt.list Modlist.pp) jobs;
    in_dir (Info.root i) (fun () ->
      if !manage_opam_packages_ then configure_opam i;
      configure_bootvar i;
      configure_main i jobs ;
      ()
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
      if !manage_opam_packages_ then clean_opam ();
      clean_bootvar i;
      clean_main i jobs;
      command "rm -rf %s/_build" root ;
      command "rm -rf log %s/main.native.o %s/main.native %s/*~"
        root root root ;
    )

  (* Compile the configuration file and attempt to dynlink it.
   * It is responsible for registering an application via
   * [register] in order to have an observable
   * side effect to this command. *)
  let compile_and_dynlink file =
    info "%a %s" blue "Processing:" file;
    let root = Filename.dirname file in
    let file = Filename.basename file in
    let file = Dynlink.adapt_filename file in
    command "rm -rf %s/_build/%s.*" root (Filename.chop_extension file);
    command "cd %s && ocamlbuild -use-ocamlfind -tags annot,bin_annot -pkg %s %s" root P.name file ;
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

  let load file =
    scan_conf file >>= fun file ->
    let root = realpath (Filename.dirname file) in
    let file = root / Filename.basename file in
    set_config_file file;
    compile_and_dynlink file >>= fun () ->
    registered () >>= fun t ->
    set_section (Config.name t);
    Ok t


  let primary_keys t =
    Key.term ~stage:`Configure @@ Config.primary_keys t

  let eval t =
    let evaluated, info = Config.eval t in
    object
      method configure = configure info evaluated
      method clean = clean info evaluated
      method build = build info
      method keys =
        Key.term ~stage:`Configure @@ Info.keys info
    end

end
