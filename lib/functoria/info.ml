(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2020 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2015-2020 Gabriel Radanne <drupyog@zoho.com>
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

open Astring

type t = {
  name : string;
  output : string option;
  build_dir : Fpath.t;
  keys : Key.Set.t;
  context : Key.context;
  packages : Package.t String.Map.t;
  opam : Opam.t;
}

let name t = t.name

let opam t = t.opam

let build_dir t = t.build_dir

let output t = t.output

let with_output t output = { t with output = Some output }

let libraries ps =
  let libs p =
    if Package.build_dependency p then String.Set.empty
    else String.Set.of_list (Package.libraries p)
  in
  String.Set.elements
    (List.fold_left String.Set.union String.Set.empty (List.map libs ps))

let packages t = List.map snd (String.Map.bindings t.packages)

let libraries t = libraries (packages t)

let package_names t = List.map Package.name (packages t)

let pins packages =
  List.fold_left
    (fun acc p ->
      match Package.pin p with
      | None -> acc
      | Some u -> (Package.name p, u) :: acc)
    [] packages

let keys t = Key.Set.elements t.keys

let context t = t.context

let v ~packages ~keys ~context ~build_dir ~build_cmd ~src name =
  let keys = Key.Set.of_list keys in
  let opam =
    Opam.v ~depends:packages ~pins:(pins packages) ~build:build_cmd ~src name
  in
  let packages =
    List.fold_left
      (fun m p ->
        let n = Package.name p in
        match String.Map.find n m with
        | None -> String.Map.add n p m
        | Some p' -> (
            match Package.merge p p' with
            | Some p -> String.Map.add n p m
            | None -> m ))
      String.Map.empty packages
  in
  { name; build_dir; keys; packages; context; output = None; opam }

let pp_packages ?(surround = "") ?sep ppf t =
  Fmt.pf ppf "%a" (Fmt.iter ?sep List.iter (Package.pp ~surround)) (packages t)

let pp verbose ppf ({ name; build_dir; keys; context; output; _ } as t) =
  let show name = Fmt.pf ppf "@[<2>%s@ %a@]@," name in
  let list = Fmt.iter ~sep:(Fmt.unit ",@ ") List.iter Fmt.string in
  show "Name      " Fmt.string name;
  show "Build-dir " Fpath.pp build_dir;
  show "Keys      " (Key.pps context) keys;
  show "Output    " Fmt.(option string) output;
  if verbose then show "Libraries " list (libraries t);
  if verbose then
    show "Packages  " (pp_packages ?surround:None ~sep:(Fmt.unit ",@ ")) t

(* Device *)

open Action.Infix

let src = Logs.Src.create "functoria" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

let t =
  let i =
    v ~packages:[] ~keys:[] ~context:Key.empty_context ~build_cmd:[]
      ~build_dir:Fpath.(v "dummy")
      ~src:`None "dummy"
  in
  Type.v i

let pp_libraries fmt l =
  Fmt.pf fmt "[@ %a]" Fmt.(iter ~sep:(unit ";@ ") List.iter @@ fmt "%S") l

let pp_packages fmt l =
  Fmt.pf fmt "[@ %a]"
    Fmt.(
      iter ~sep:(unit ";@ ") List.iter @@ fun fmt (n, v) -> pf fmt "%S, %S" n v)
    l

let pp_dump_pkgs modname fmt (name, pkg, libs) =
  Fmt.pf fmt
    "%s.{@ name = %S;@ @[<v 2>packages = %a@]@ ;@ @[<v 2>libraries = %a@]@ }"
    modname name pp_packages (String.Map.bindings pkg) pp_libraries
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
  Action.run_cmd_out cmd >>= fun deps ->
  let deps = String.cuts ~empty:false ~sep:"\n" deps in
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
  Action.ok deps

let app_info v ?(runtime_package = "functoria-runtime") ?opam_list
    ?(gen_modname = "Info_gen") ?(modname = "Functoria_runtime") () =
  let file = Fpath.(v (String.Ascii.lowercase gen_modname) + "ml") in
  let module_name = gen_modname in
  let connect _ impl_name _ = Fmt.strf "return %s.info" impl_name in
  let clean _ = Action.rm file in
  let build i =
    Log.info (fun m -> m "Generating: %a" Fpath.pp file);
    let packages =
      match opam_list with
      | None -> default_opam_deps (package_names i)
      | Some pkgs -> Action.ok (String.Map.of_list pkgs)
    in
    packages >>= fun opam ->
    let ocl = String.Set.of_list (libraries i) in
    Fmt.kstr (Action.write_file file) "@[<v 2>let info = %a@]"
      (pp_dump_pkgs modname)
      (name i, opam, ocl)
  in
  let packages = [ Package.v runtime_package ] in
  v ~packages ~connect ~clean ~build module_name t
