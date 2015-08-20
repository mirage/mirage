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
    libraries : string list;
    packages : string list;
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
  class type ['ty] configurable = object ('self)
    method ty : 'ty typ
    method name: string
    method module_name: string
    method packages: string list
    method libraries: string list
    method keys: Key.t list
    method connect : Info.t -> string -> string list -> string option
    method configure: Info.t -> unit
    method clean: unit
    method update_path: string -> 'self
    method dependencies: job Typ.impl list
  end

  type _ impl =
    | Impl: 'ty configurable -> 'ty impl (* base implementation *)
    | App: ('a, 'b) app -> 'b impl   (* functor application *)
    | If : bool Key.value * 'a impl * 'a impl -> 'a impl
    | Dep : ('a, 'b) dep -> 'a impl

  and ('a, 'b) app = {
    f: ('a -> 'b) impl;  (* functor *)
    x: 'a impl;          (* parameter *)
  }

  and ('a, 'b) dep = {
    md: 'a impl ; (* a module *)
    dep: 'b impl ; (* a dependency *)
  }

end = Typ
include Typ


let ($) f x =
  App { f; x }

let ($$) md dep =
  Dep { md; dep }

let impl x = Impl x

let switch b x y = If(b,x,y)

class dummy_conf = object
  method libraries : string list = []
  method packages : string list = []
  method keys : Key.t list = []
  method connect (_:Info.t) (_:string) (_ : string list) : string option = None
  method configure (_ : Info.t) = ()
  method clean = ()
  method update_path (_s: string) = {< >}
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
    | Dep {md = If (b, f1, f2) ; dep} -> switch b (f1$$dep) (f2$$dep), true
    | Dep {md ; dep = If(b, x1, x2)} -> switch b (md$$x1) (md$$x2), true
    | Dep {md ; dep } ->
      let f, bf = push_app' md and x, bx = push_app' dep in
      let b = bf || bx in
      if b then fst @@ push_app' (f $$ x), true else f $$ x, false
    | If (b, x, y) ->
      let x, bx = push_app' x and y, by = push_app' y in
      switch b x y, bx || by
    | Impl c as f ->
      match c#dependencies with
      | [] -> f, false
      | l ->
        push_app' @@ List.fold_left ($$) f l

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

module Modlist = struct

  type t = {
    m : modlist ;
    deps : t list ;
  }

  and modlist =
    | Mod  : _ configurable -> modlist
    | List : _ configurable * t list -> modlist

  let appm f { m ; deps } = { m = f m ; deps }

  let rec linearize
    : type ty . ty impl -> t
    = function
      | Impl m -> { m = Mod m ; deps = [] }
      | If _ -> assert false
      | Dep { md ; dep } ->
        let { m ; deps } = linearize md in
        { m ; deps = linearize dep :: deps }
      | App { f ; x } ->
        let fuse = function
          | Mod m -> List (m, [linearize x])
          | List (funct, args) -> List (funct, args @ [linearize x])
        in appm fuse @@ linearize f

  let of_impl i =
    DTree.map linearize (DTree.to_tree i)

  let rec pp : t Fmt.t = fun fmt -> function
    | {m = Mod d}          -> Fmt.string fmt d#module_name
    | {m = List (f, args)} ->
      Fmt.pf fmt "%s%a"
        f#module_name
        Fmt.(parens @@ list pp) args


  (** Return a unique variable name holding the state of the given
      module construction. *)
  let rec name = function
    | {m = Mod d}           -> d#name
    | {m = List (f,_)} as t -> Name.of_key (module_name t) ~base:f#name

  (** Return a unique module name holding the implementation of the
      given module construction. *)
  and module_name = function
    | {m = Mod d}          -> d#module_name
    | {m = List (f, args)} ->
      let name = body (Mod f) args in
      Name.of_key name ~base:"F"

  and body f args =
    functor_name f ^
      Fmt.(strf "%a" (list ~pp_sep:nop @@ parens string)
        (List.map module_name args))

  and functor_name = function
    | Mod d      -> d#module_name
    | List (f,_) -> f#module_name


  type 'a mapper = {
    map: 'ty. 'ty configurable -> 'a
  }

  let flatmap f l = List.concat @@ List.map f l

  let rec to_list flatmap append fm {m;deps} =
    append (flatmap (to_list flatmap append fm) deps) @@ match m with
      | Mod d -> fm.map d
      | List (f, args) ->
        append (fm.map f) (flatmap (to_list flatmap append fm) args)

  let packages  = to_list flatmap (@) { map = fun x -> x#packages  }
  let libraries = to_list flatmap (@) { map = fun x -> x#libraries }
  let keys      = to_list flatmap (@) { map = fun x -> x#keys      }


  let configured = Hashtbl.create 31

  let rec configure info t =
    let name = name t in
    if not (Hashtbl.mem configured name) then begin
      Hashtbl.add configured name true;
      List.iter (configure info) t.deps ;
      begin match t.m with
      | Mod t -> t#configure info
      | List (f, args) ->
        List.iter (configure info) args ;
        f#configure info ;
        let modname = module_name t in
        let body = body (Mod f) args in
        Codegen.append_main "module %s = %s" modname body;
        Codegen.newline_main ();
      end ;
    end

  let connect_string info m modname l =
    match m#connect info modname l with
    | Some s -> s
    | None ->
      Printf.sprintf "return (`Ok (%s))" (String.concat ", " l)

  let rec connect info error t =
    let iname = name t in
    let modname = module_name t in
    List.iter (connect info error) t.deps ;
    match t.m with
    | Mod m ->
      Codegen.append_main "let %s () =" iname;
      Codegen.append_main "  %s" (connect_string info m modname []);
      Codegen.newline_main ()
    | List (f, args) ->
      List.iter (connect info error) args ;
      let names = List.map name (args @ t.deps) in
      Codegen.append_main "let %s () =" iname;
      List.iter (fun n ->
        Codegen.append_main "  %s () >>= function" n;
        Codegen.append_main "  | `Error e -> %s" (error n);
        Codegen.append_main "  | `Ok %s ->" n;
      ) names;
      Codegen.append_main "  %s" (connect_string info f modname names);
      Codegen.newline_main ()


  let configure_and_connect info error t =
    configure info t ;
    connect info error t

  type iter = {
    i : 'ty. 'ty configurable -> unit
  }

  let rec iter fi {m;deps} =
    List.iter (iter fi) deps ;
    match m with
    | Mod b -> fi.i b
    | List (f, args) ->
      List.iter (iter fi) args ; fi.i f

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
      Some (Printf.sprintf "%s.start %s" m (String.concat " " args))
    method clean = ()
    method configure _ = ()
    method update_path _ = {<>}
    method dependencies = []
  end

let foreign ?keys ?libraries ?packages module_name ty =
  Impl (new foreign ?keys ?libraries ?packages module_name ty)

module Config = struct

  type t = {
    info : Info.t ;
    jobs : Modlist.t DTree.t list ;
    custom : job configurable
  }

  let get_packages jobs =
    List.fold_left (fun set j ->
      DTree.to_list Modlist.packages j @ set
    ) [] jobs

  let get_libraries jobs =
    List.fold_left (fun set j ->
      DTree.to_list Modlist.libraries j @ set
    ) [] jobs

  let get_keys jobs =
    let ks = List.fold_left (fun set j ->
        Key.Set.union (DTree.keys j) set
      ) Key.Set.empty jobs
    in
    let ks = List.fold_left (fun set j ->
        List.fold_left (fun set k -> Key.Set.add k set)
          set (DTree.to_list Modlist.keys j)
      ) ks jobs in
    ks

  let make
      ?keys:(k=[]) ?libraries:(l=[]) ?packages:(p=[])
      name root jobs init_dsl =
    let custom = init_dsl ~name ~root jobs in
    let jobs =
      List.map Modlist.of_impl (impl custom :: jobs)
    in
    let keys = Key.Set.(union (of_list k) @@ get_keys jobs) in
    let libraries = l @ get_libraries jobs in
    let packages = p @ get_packages jobs in
    let info = {Info. name; keys ; packages ; libraries ; root } in
    { info ; jobs ; custom }

  let name t = t.info.name
  let root t = t.info.root
  let keys t = t.info.keys
  let jobs t = t.jobs

end

type config = Config.t


module type PROJECT = sig

  val name : string

  val version : string

  val driver_error : string -> string

  class conf :
    name:string -> root:string -> job impl list ->
    [job] configurable

end


module type CONFIG = sig
  module Project : PROJECT

  val register:
    ?keys:Key.t list -> ?libraries:string list -> ?packages:string list ->
    string -> job impl list -> unit

  val manage_opam_packages: bool -> unit
  val no_opam_version_check: bool -> unit
  val no_depext: bool -> unit

  val dummy_conf : Config.t
  val load: string option -> (Config.t, string) Rresult.result

  val configure: Config.t -> unit
  val clean: Config.t -> unit
  val build: Config.t -> unit
  val cmdliner: Config.t -> unit Cmdliner.Term.t
end

module Make (P:PROJECT) = struct
  module Project = P

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
    let init_dsl = new P.conf in
    Config.make name root [] init_dsl

  let register ?(keys=[]) ?(libraries=[]) ?(packages=[]) name jobs =
    let root = get_root () in
    let init_dsl = new P.conf in
    let c =
      Config.make ~keys ~libraries ~packages name root jobs init_dsl
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
    match t.Info.packages with
    | [] -> ()
    | ps ->
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


  let configure_bootvar t =
    info "%a bootvar_gen.ml" blue "Generating:";
    Fmt.with_file (Config.root t / "bootvar_gen.ml") @@ fun fmt ->
    Codegen.append fmt "(* %s *)" (generated_header t.custom#name) ;
    Codegen.newline fmt;
    let bootvars =
      Key.Set.elements @@ Key.Set.filter Key.is_runtime @@ Config.keys t
    in
    List.iter (Key.emit fmt) bootvars ;
    Codegen.newline fmt;
    Codegen.append fmt "let keys = %a"
      Fmt.(brackets @@
        list ~pp_sep:(const char ';' <@ sp) (string <@ const string "_t"))
      (List.map Key.name bootvars);
    Codegen.newline fmt

  let clean_bootvar t =
    remove (Config.root t / "bootvar_gen.ml")


  let configure_main t =
    info "%a main.ml" blue "Generating:";
    Codegen.set_main_ml (Config.root t / "main.ml");
    Codegen.append_main "(* %s *)" (generated_header t.custom#name);
    Codegen.newline_main ();
    Codegen.append_main "open Lwt";
    Codegen.newline_main ();
    Codegen.append_main "let _ = Printexc.record_backtrace true";
    Codegen.newline_main ();
    let jobs = List.map DTree.eval @@ Config.jobs t in
    List.iter (Modlist.configure_and_connect t.info Project.driver_error) jobs;
    let args = List.map (fun j -> Printf.sprintf "(%s ())" (Modlist.name j)) jobs in
    begin match t.custom#connect t.info "Main" args with
      | None -> ()
      | Some s ->
        Codegen.newline_main ();
        Codegen.append_main "let () =";
        Codegen.append_main "  %s" s;
    end

  let clean_main t =
    List.iter (DTree.iter Modlist.clean) @@ Config.jobs t;
    remove (Config.root t / "main.ml")

  let configure t =
    info "%a %s" blue "Using configuration:"  (get_config_file ());
    let jobs = List.map DTree.eval @@ Config.jobs t in
    info "%a@ [%a]"
      blue (Fmt.strf "%d Job%s:"
        (List.length jobs)
        (if List.length jobs = 1 then "" else "s"))
      (Fmt.list Modlist.pp) jobs;
    in_dir (Config.root t) (fun () ->
      if !manage_opam_packages_ then configure_opam t.info;
      configure_bootvar t;
      configure_main t ;
      t.custom#configure t.info ;
      ()
    )

  let make () =
    match uname_s () with
    | Some ("FreeBSD" | "OpenBSD" | "NetBSD" | "DragonFly") -> "gmake"
    | _ -> "make"

  let build t =
    info "%a %s" blue "Build:" (get_config_file ());
    in_dir (Config.root t) (fun () ->
      command "%s build" (make ())
    )

  let clean t =
    info "%a %s" blue "Clean:"  (get_config_file ());
    let root = Config.root t in
    in_dir root (fun () ->
      if !manage_opam_packages_ then clean_opam t;
      clean_bootvar t;
      clean_main t;
      command "rm -rf %s/_build" root ;
      command "rm -rf log %s/main.native.o %s/main.native %s/*~"
        root root root ;
      t.custom#clean
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

  let cmdliner t =
    Key.(term @@ Set.filter is_configure @@ Config.keys t)

end
