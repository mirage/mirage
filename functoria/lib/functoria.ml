(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
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
open Functoria_misc
module Key = Functoria_key
module Package = Functoria_package
module Info = Functoria_info
include Functoria_s

let package = Package.v

let ( @-> ) = Functoria_type.( @-> )

let typ = Functoria_type.v

let ( $ ) f x = App { f; x }

let of_device x = Dev x

let abstract x = Abstract x

let if_impl b x y = If (b, x, y)

let rec match_impl kv ~default = function
  | [] -> default
  | (f, i) :: t -> If (Key.(pure (( = ) f) $ kv), i, match_impl kv ~default t)

let rec pp_impl : type a. a impl Fmt.t =
 fun ppf -> function
  | Dev d -> Fmt.pf ppf "Dev %a" pp_device d
  | App a -> Fmt.pf ppf "App %a" pp_app a
  | If (_, x, y) -> Fmt.pf ppf "If (_,%a,%a)" pp_impl x pp_impl y

and pp_app : type a b. (a, b) app Fmt.t =
 fun ppf t -> Fmt.pf ppf "{@[ f: %a;@, x: %a @]}" pp_impl t.f pp_impl t.x

and pp_abstract_impl ppf (Abstract i) = pp_impl ppf i

and pp_device : type a. a device Fmt.t =
 fun ppf t ->
  let open Fmt.Dump in
  let fields =
    [
      field "id" (fun t -> t.id) Fmt.int;
      field "module_name" (fun t -> t.module_name) string;
      field "module_type" (fun t -> t.module_type) Functoria_type.pp;
      field "keys" (fun t -> t.keys) (list Functoria_key.pp);
      field "packages" (fun t -> t.packages) Functoria_key.pp_deps;
      field "extra_deps" (fun t -> t.extra_deps) (list pp_abstract_impl);
    ]
  in
  record fields ppf t

let equal_device x y = x.id = y.id

let rec equal : type t1 t2. t1 impl -> t2 impl -> bool =
 fun x y ->
  match (x, y) with
  | Dev c, Dev c' -> equal_device c c'
  | App a, App b -> equal a.f b.f && equal a.x b.x
  | If (cond1, t1, e1), If (cond2, t2, e2) ->
      (* Key.value is a functional value (it contains a closure for eval).
         There is no prettier way than physical equality. *)
      cond1 == cond2 && equal t1 t2 && equal e1 e2
  | Dev _, (If _ | App _) | App _, (If _ | Dev _) | If _, (App _ | Dev _) ->
      false

module Device = struct
  let pp = pp_device

  let equal = equal_device

  let default_connect _ _ l =
    Printf.sprintf "return (%s)" (String.concat ~sep:", " l)

  let niet _ = Ok ()

  type 'a t = 'a device

  type 'a code = string

  let merge_packages packages packages_v =
    match (packages, packages_v) with
    | None, None -> Key.pure []
    | Some p, None -> Key.pure p
    | None, Some p -> p
    | Some a, Some b -> Key.(pure List.append $ pure a $ b)

  let count =
    let i = ref 0 in
    fun () ->
      incr i;
      !i

  let v ?packages ?packages_v ?(keys = []) ?(extra_deps = [])
      ?(connect = default_connect) ?(configure = niet) ?(build = niet)
      ?(clean = niet) module_name module_type =
    let id = count () in
    let packages = merge_packages packages packages_v in
    {
      module_type;
      id;
      module_name;
      keys;
      connect;
      packages;
      clean;
      configure;
      build;
      extra_deps;
    }

  let id t = t.id

  let module_name t = t.module_name

  let module_type t = t.module_type

  let packages t = t.packages

  let connect t = t.connect

  let configure t = t.configure

  let build t = t.build

  let clean t = t.clean

  let keys t = t.keys

  let extra_deps t = t.extra_deps

  let start impl_name args =
    Fmt.strf "@[%s.start@ %a@]" impl_name Fmt.(list ~sep:sp string) args

  let exec_hook i = function None -> Ok () | Some h -> h i

  let extend ?packages ?packages_v ?pre_configure ?post_configure ?pre_build
      ?post_build ?pre_clean ?post_clean t =
    let packages =
      Key.(pure List.append $ merge_packages packages packages_v $ t.packages)
    in
    let exec pre f post i =
      exec_hook i pre >>= fun () ->
      f i >>= fun () -> exec_hook i post
    in
    let configure = exec pre_configure t.configure post_configure in
    let build = exec pre_build t.build post_build in
    let clean = exec pre_clean t.clean post_clean in
    { t with packages; configure; build; clean }
end

let impl ?packages ?packages_v ?keys ?extra_deps ?connect ?configure ?build
    ?clean module_name module_type =
  of_device
  @@ Device.v ?packages ?packages_v ?keys ?extra_deps ?connect ?configure ?build
       ?clean module_name module_type

let main ?packages ?packages_v ?keys ?extra_deps module_name ty =
  let connect _ = Device.start in
  impl ?packages ?packages_v ?keys ?extra_deps ~connect module_name ty

let foreign ?packages ?packages_v ?keys ?deps module_name ty =
  main ?packages ?packages_v ?keys ?extra_deps:deps module_name ty

(* {Misc} *)

let rec hash : type t. t impl -> int = function
  | Dev c -> hash_device c
  | App { f; x } -> Hashtbl.hash (`Bla (hash f, hash x))
  | If (cond, t, e) -> Hashtbl.hash (`If (cond, hash t, hash e))

and hash_device : type t. t device -> int =
 fun c ->
  Hashtbl.hash
    ( c.module_name,
      c.module_type,
      Hashtbl.hash c.keys,
      List.map hash_any c.extra_deps )

and hash_any (Abstract x) = hash x

module ImplTbl = Hashtbl.Make (struct
  type t = abstract_impl

  let hash = hash_any

  let equal = ( == )
end)

let explode x =
  match x with
  | Dev c -> `Dev c
  | App { f; x } -> `App (Abstract f, Abstract x)
  | If (cond, x, y) -> `If (cond, x, y)

type context = Functoria_key.context

type abstract_key = Functoria_key.t

module type KEY =
  module type of Functoria_key
    with type 'a Arg.converter = 'a Functoria_key.Arg.converter
     and type 'a Arg.t = 'a Functoria_key.Arg.t
     and type Arg.info = Functoria_key.Arg.info
     and type 'a value = 'a Functoria_key.value
     and type 'a key = 'a Functoria_key.key
     and type t = Functoria_key.t
     and type Set.t = Functoria_key.Set.t
     and type 'a Alias.t = 'a Functoria_key.Alias.t
     and type context = Functoria_key.context

(** Devices *)

let src = Logs.Src.create "functoria" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

type job = JOB

let job = typ JOB

(* Noop, the job that does nothing. *)
let noop = impl "Unit" job

(* Default argv *)
type argv = ARGV

let argv = typ ARGV

let sys_argv =
  let connect _ _ _ = "return Sys.argv" in
  impl ~connect "Sys" argv

(* Keys *)

module Keys = struct
  let with_output f k =
    Bos.OS.File.with_oc f k ()
    >>= R.reword_error_msg (fun _ ->
            `Msg (Fmt.strf "couldn't open output channel %a" Fpath.pp f))

  let configure ~file i =
    Log.info (fun m -> m "Generating: %a" Fpath.pp file);
    with_output file (fun oc () ->
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
          Fmt.Dump.(list pp_runvar)
          runvars
          Fmt.Dump.(list pp_names)
          runvars;
        Codegen.newline fmt;
        Ok ())

  let clean ~file _ = Bos.OS.Path.delete file
end

let keys (argv : argv impl) =
  let packages = [ package "functoria-runtime" ] in
  let extra_deps = [ abstract argv ] in
  let module_name = Key.module_name in
  let file = Fpath.(v (String.Ascii.lowercase module_name) + "ml") in
  let configure = Keys.configure ~file and clean = Keys.clean ~file in
  let connect info impl_name = function
    | [ argv ] ->
        Fmt.strf
          "return (Functoria_runtime.with_argv (List.map fst %s.runtime_keys) \
           %S %s)"
          impl_name (Info.name info) argv
    | _ -> failwith "The keys connect should receive exactly one argument."
  in
  impl ~configure ~clean ~packages ~extra_deps ~connect module_name job

(* Module emiting a file containing all the build information. *)

let info =
  let i =
    Info.create ~packages:[] ~keys:[] ~context:Key.empty_context ~name:"dummy"
      ~build_dir:Fpath.(v "dummy")
  in
  typ i

let pp_libraries fmt l =
  Fmt.pf fmt "[@ %a]" Fmt.(iter ~sep:(unit ";@ ") List.iter @@ fmt "%S") l

let pp_packages fmt l =
  Fmt.pf fmt "[@ %a]"
    Fmt.(
      iter ~sep:(unit ";@ ") List.iter @@ fun fmt (n, v) -> pf fmt "%S, %S" n v)
    l

let pp_dump_pkgs fmt (name, pkg, libs) =
  Fmt.pf fmt
    "Functoria_runtime.{@ name = %S;@ @[<v 2>packages = %a@]@ ;@ @[<v \
     2>libraries = %a@]@ }"
    name pp_packages (String.Map.bindings pkg) pp_libraries
    (String.Set.elements libs)

(* this used to call 'opam list --rec ..', but that leads to
   non-reproducibility, since this uses the opam CUDF solver which
   drops some packages (which are in the repositories configured for
   the switch), see https://github.com/mirage/functoria/pull/189 for
   further discussion on this before changing the code below.

   This also used to call `opam list --installed --required-by <pkgs>`,
   but that was not precise enough as this was 1/ computing the
   dependencies for all version of <pkgs> and 2/ keeping only the
   installed packages. `opam list --installed --resolve <pkgs>` will
   compute the dependencies of the installed versions of <pkgs>.  *)
let default_opam_deps pkgs =
  let pkgs_str = String.concat ~sep:"," pkgs in
  let cmd =
    Bos.Cmd.(
      v "opam"
      % "list"
      % "--installed"
      % "-s"
      % "--color=never"
      % "--depopts"
      % "--resolve"
      % pkgs_str
      % "--columns"
      % "name,version")
  in
  Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_lines >>= fun (deps, _) ->
  let deps =
    List.fold_left
      (fun acc s ->
        match String.cuts ~empty:false ~sep:" " s with
        | [ n; v ] -> (n, v) :: acc
        | _ -> assert false)
      [] deps
  in
  let deps = String.Map.of_list deps in
  let roots = String.Set.of_list pkgs in
  let deps = String.Set.fold String.Map.remove roots deps in
  Ok deps

let app_info ?opam_deps ?(gen_modname = "Info_gen") () =
  let file = Fpath.(v (String.Ascii.lowercase gen_modname) + "ml") in
  let module_name = gen_modname in
  let packages = [ package "functoria-runtime" ] in
  let connect _ impl_name _ = Fmt.strf "return %s.info" impl_name in
  let clean _ = Bos.OS.Path.delete file in
  let build i =
    Log.info (fun m -> m "Generating: %a" Fpath.pp file);
    let opam_deps =
      match opam_deps with
      | None -> default_opam_deps (Info.package_names i)
      | Some pkgs -> Ok (String.Map.of_list pkgs)
    in
    opam_deps >>= fun opam ->
    let ocl = String.Set.of_list (Info.libraries i) in
    Bos.OS.File.writef file "@[<v 2>let info = %a@]" pp_dump_pkgs
      (Info.name i, opam, ocl)
  in
  impl ~packages ~connect ~clean ~build module_name info

module Type = Functoria_type
