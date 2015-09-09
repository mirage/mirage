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

(** The core Dsl *)
module Dsl = struct

  type _ typ =
    | Type: 'a -> 'a typ
    | Function: 'a typ * 'b typ -> ('a -> 'b) typ

  let (@->) f t =
    Function (f, t)

  let typ ty = Type ty

  module rec Typ : sig

    type _ impl =
      | Impl: 'ty Typ.configurable -> 'ty impl (* base implementation *)
      | App: ('a, 'b) app -> 'b impl   (* functor application *)
      | If : bool Key.value * 'a impl * 'a impl -> 'a impl

    and ('a, 'b) app = {
      f: ('a -> 'b) impl;  (* functor *)
      x: 'a impl;          (* parameter *)
    }

    and any_impl = Any : _ impl -> any_impl

    class type ['ty] configurable = object
      method ty : 'ty typ
      method name: string
      method module_name: string
      method keys: Key.t list
      method packages: string list Key.value
      method libraries: string list Key.value
      method connect : Info.t -> string -> string list -> string
      method configure: Info.t -> unit
      method clean: Info.t -> unit
      method dependencies : any_impl list
    end
  end = Typ
  include Typ


  let ($) f x =
    App { f; x }

  let impl x = Impl x
  let hide x = Any x

  let if_impl b x y = If(b,x,y)
  let rec switch ~default l kv = match l with
    | [] -> default
    | (v, i) :: t ->
      If (Key.(pure ((=) v) $ kv), i, switch ~default t kv)



  class base_configurable = object
    method libraries : string list Key.value = Key.pure []
    method packages : string list Key.value = Key.pure []
    method keys : Key.t list = []
    method connect (_:Info.t) (_:string) l =
      Printf.sprintf "return (`Ok (%s))" (String.concat ", " l)
    method configure (_ : Info.t) = ()
    method clean (_ : Info.t)= ()
    method dependencies : any_impl list = []
  end


  type job = JOB
  let job = Type JOB

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
      method libraries = Key.pure libraries
      method packages = Key.pure packages
      method connect _ modname args =
        Fmt.strf
          "@[%s.start@ %a@ >>= fun t -> Lwt.return (`Ok t)@]"
          modname
          Fmt.(list ~sep:sp string)  args
      method clean _ = ()
      method configure _ = ()
      method dependencies = []
    end

  let foreign ?keys ?libraries ?packages module_name ty =
    Impl (new foreign ?keys ?libraries ?packages module_name ty)

end
include Dsl

(** Decision trees *)
module DTree = struct

  type +'a t =
    | Leaf : 'a -> 'a t
    | If : bool Key.value * 'a t * 'a t -> 'a t

  let rec push_app' : type a. a impl -> a impl * bool  = function
    | App {f = If (b, f1, f2) ;x} ->
      push_app' @@ if_impl b (f1$x) (f2$x)
    | App {f ; x = If(b, x1, x2)} ->
      push_app' @@ if_impl b (f$x1) (f$x2)
    | App {f ; x } ->
      let f, bf = push_app' f and x, bx = push_app' x in
      let b = bf || bx in
      if b then fst @@ push_app' (f $ x), true else f $ x, false
    | If (b, x, y) ->
      let x, bx = push_app' x and y, by = push_app' y in
      if_impl b x y, bx || by
    | Impl _ as f -> f, false

  let push_app i = fst @@ push_app' i

  let rec to_tree_internal : type a. a impl -> a impl t = function
    | If (b, x, y) -> If (b, to_tree_internal x, to_tree_internal y)
    | t -> Leaf t

  let to_tree x = to_tree_internal (push_app x)

  let rec map f = function
    | Leaf x -> Leaf (f x)
    | If (b, x, y) -> If (b, map f x, map f y)

  let rec keys = function
    | Leaf _ -> Key.Set.empty
    | If (b,x,y) ->
      Key.Set.union (Key.deps b) @@
      Key.Set.union (keys x) (keys y)

  let rec partial_eval = function
    | Leaf _ as t -> t
    | If (b, x, y) -> match Key.peek b with
      | None -> If (b, partial_eval x, partial_eval y)
      | Some true -> partial_eval x
      | Some false -> partial_eval y

  let rec eval = function
    | Leaf c -> c
    | If (b, x, y) ->
      if Key.eval b then eval x else eval y

  let rec pp ppf fmt = function
    | Leaf x -> ppf fmt x
    | If (b, x, y) ->
      Fmt.pf fmt "@[<v 2>Depending on the key %a:@,%a@,%a@]"
        (Fmt.styled `Bold @@ Key.pp_deps) b
        (pp ppf) x
        (pp ppf) y

end

module Modlist : sig
  type t
  type evaluated

  val of_impl : job impl -> t
  val eval : t list -> evaluated list

  val primary_keys : t list -> Key.Set.t

  val keys : evaluated list -> Key.Set.t
  val packages : evaluated list -> StringSet.t Key.value
  val libraries : evaluated list -> StringSet.t Key.value

  val configure_and_connect :
    Info.t -> (string -> string) -> evaluated list -> unit

  val clean : Info.t -> evaluated -> unit

  val partial_eval : t -> t

  val pp : evaluated Fmt.t
  val describe : t list Fmt.t

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
      | Impl m ->
        Mod (m,List.map (fun (Any i) -> of_impl i) m#dependencies)
      | If _ -> assert false
      | App { f ; x } ->
        let fuse = function
          | Mod (m, deps) -> List (m, deps, [linearize x])
          | List (m, deps, args) -> List (m, deps , args @ [linearize x])
        in fuse @@ linearize f

  and of_impl
    : type ty . ty impl -> t
    = fun i -> T (DTree.map linearize (DTree.to_tree i))

  let rec pp_modlist : 'a modlist Fmt.t = fun fmt -> function
    | Mod (d, _)        -> Fmt.string fmt d#module_name
    | List (f, _, args) ->
      Fmt.pf fmt "@[<2>%s@ %a@]"
        f#module_name
        Fmt.(list ~sep:sp @@ parens @@ box pp_modlist) args

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

  module type S = sig
    type t
    val flatmap : ('a -> t) -> 'a list -> t
    val (@) : t -> t -> t
  end

  let collect (type t) (module M:S with type t=t) map fm m =
    let open M in
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

  module M = struct
    type t = StringSet.t Key.value
    let (@) x y = Key.(pure StringSet.union $ x $ y)
    let flatmap f l =
      List.fold_left
        (fun set x -> f x @ set)
        (Key.pure StringSet.empty)
        l
  end

  let collect_E modu fm m = collect modu map_E fm m
  let packages  =
    collect_E (module M) { map = fun x -> Key.map StringSet.of_list x#packages }
  let libraries =
    collect_E (module M) { map = fun x -> Key.map StringSet.of_list x#libraries }

  let keys =
    let module M = struct
      include Key.Set
      let (@) = union
      let flatmap f = List.fold_left (fun set x -> f x @ set)  empty
    end
    in collect_E (module M) {map = fun x -> Key.Set.of_list x#keys}


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

  let rec connect' tbl info error m =
    let iname = name m in
    if not (Hashtbl.mem tbl iname) then begin
      Hashtbl.add tbl iname true;
      let modname = module_name m in
      match m with
      | Mod (m, deps) ->
        List.iter (connect tbl info error) deps ;
        let names = List.map (map_E name) deps in
        Codegen.append_main "%a"
          emit_connect (error, iname, names, m#connect info modname)
      | List (f, deps, args) ->
        List.iter (connect' tbl info error) args ;
        List.iter (connect tbl info error) deps ;
        let names = List.map name args @ List.map (map_E name) deps in
        Codegen.append_main "%a"
          emit_connect (error, iname, names, f#connect info modname)
    end
  and connect tbl info error (E m) = connect' tbl info error m

  let configure_and_connect info error l =
    let configured = Hashtbl.create 31 in
    let connected = Hashtbl.create 31 in
    List.iter (fun m ->
      configure configured info m ;
      connect connected info error m)
      l

  let partial_eval (T t) = T (DTree.partial_eval t)

  type iter = { i : 'ty. 'ty configurable -> unit }

  let rec iter' fi m =
    match m with
    | Mod (b, deps) -> List.iter (iter fi) deps ; fi.i b
    | List (f, deps, args) ->
      List.iter (iter fi) deps ; List.iter (iter' fi) args ; fi.i f
  and iter fi (E m) = iter' fi m

  let clean i t = iter { i = fun t -> t#clean i} t

  let describe_one fmt (T t) =
    Fmt.pf fmt "%a %a" yellow "-" (DTree.pp pp_modlist) t
  let describe =
    Fmt.(vbox @@ list describe_one)

end

module Config = struct

  type t = {
    name : string ;
    root : string ;
    libraries : StringSet.t Key.value ;
    packages : StringSet.t Key.value ;
    keys : Key.Set.t ;
    jobs : Modlist.t list ;
    custom : job configurable ;
  }

  let make
      ?(keys=[]) ?(libraries=[]) ?(packages=[])
      name root jobs init_dsl =
    let custom = init_dsl ~name ~root jobs in
    let jobs = List.map Modlist.of_impl @@ impl custom :: jobs in

    let libraries = Key.pure @@ StringSet.of_list libraries in
    let packages = Key.pure @@ StringSet.of_list packages in
    let keys =
      Key.Set.(union (of_list (keys @ custom#keys)) (Modlist.primary_keys jobs))
    in
    { libraries ; packages ; keys ; name ; root ; jobs ; custom }

  let eval { name = n ; root ; packages ; libraries ; keys ; jobs } =
    let e = Modlist.eval jobs in
    let open Key in
    let packages = pure StringSet.union $ packages $ Modlist.packages e in
    let libraries = pure StringSet.union $ libraries $ Modlist.libraries e in
    let keys = Key.Set.union keys @@ Modlist.keys e in
    let di =
      pure (fun libraries packages ->
        {Info. libraries ; packages ; keys ; name = n ; root})
      $ libraries
      $ packages
    in
    e, with_deps ~keys di

  let name t = t.name
  let custom t = t.custom
  let primary_keys t = t.keys

  let pp fmt t =
    Modlist.describe fmt @@ List.map Modlist.partial_eval t.jobs

end

module type PROJECT = sig

  val prelude : string

  val name : string

  val version : string

  val driver_error : string -> string

  val configurable :
    name:string -> root:string -> job impl list ->
    job configurable

end

module Make (P:PROJECT) = struct
  module Project = P

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
            if no_depext then ()
            else (
              if command_exists "opam-depext" then
                info "opam depext is installed."
              else
                opam "install" ["depext"];
              opam ~yes:false "depext" ps;
            );
            Ok (opam "install" ps)
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
      (List.map Key.ocaml_name @@ Key.Set.elements bootvars);
    Codegen.newline fmt

  let clean_bootvar i =
    remove (Info.root i / "bootvar_gen.ml")


  let configure_main i jobs custom =
    info "%a main.ml" blue "Generating:";
    Codegen.set_main_ml (Info.root i / "main.ml");
    Codegen.append_main "(* %s *)" (generated_header P.name);
    Codegen.newline_main ();
    Codegen.append_main "%a" Fmt.text  Project.prelude;
    Codegen.newline_main ();
    Codegen.append_main "let _ = Printexc.record_backtrace true";
    Codegen.newline_main ();
    Modlist.configure_and_connect i Project.driver_error jobs;
    Codegen.newline_main ();
    Codegen.append_main
      "let () = run (bootvar () >>= fun _ -> %s ())" custom#name ;
    ()

  let clean_main i jobs =
    List.iter (Modlist.clean i) jobs ;
    remove (Info.root i / "main.ml")

  let configure ~no_opam ~no_depext ~no_opam_version i jobs custom =
    info "%a %s" blue "Using configuration:"  (get_config_file ());
    info "@[<v 2>%a@ %a@]@."
      blue (Fmt.strf "%d Job%s:"
        (List.length jobs)
        (if List.length jobs = 1 then "" else "s"))
      (Fmt.list Modlist.pp) jobs;
    in_dir (Info.root i) (fun () ->
      begin if no_opam
        then Ok ()
        else configure_opam ~no_depext ~no_opam_version i
      end >>= fun () ->
      configure_bootvar i;
      configure_main i jobs custom;
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
      clean_bootvar i;
      clean_main i jobs;
      command "rm -rf %s/_build" root >>= fun () ->
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

    let primary_keys t =
      Key.term ~stage:`Configure @@ Config.primary_keys t

    let eval t =
      let evaluated, info = Config.eval t in
      object
        method configure info = configure info evaluated (Config.custom t)
        method clean info = clean info evaluated
        method build info = build info
        method info = Key.term_value ~stage:`Configure info
        method describe =
          Fmt.pr "@.%a@.%a@.%!"
            green "Your current jobs are:"
            Config.pp t
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
