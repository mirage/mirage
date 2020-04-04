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

module Key = Key
module Package = Package
module Info = Info
module Type = Type
module Impl = Impl
module Device = Device
module Opam = Opam
module Lib = Lib
module Tool = Tool
module Graph = Device_graph
module Engine = Engine
module DSL = DSL
module Cli = Cli
module Action = Action
module Dune = Dune

module type DSL = module type of DSL

module type KEY =
  module type of Key
    with type 'a Arg.converter = 'a Key.Arg.converter
     and type 'a Arg.t = 'a Key.Arg.t
     and type Arg.info = Key.Arg.info
     and type 'a value = 'a Key.value
     and type 'a key = 'a Key.key
     and type t = Key.t
     and type Set.t = Key.Set.t
     and type 'a Alias.t = 'a Key.Alias.t
     and type context = Key.context

(** Devices *)

include DSL

let job = Job.t

let noop = Job.noop

let info = Info.t

let keys ?runtime_package ?runtime_modname x =
  Job.keys ?runtime_package ?runtime_modname x

type argv = Argv.t

let sys_argv = Argv.sys_argv

let argv = Argv.argv

(** info device *)

open Astring
open Action.Infix

let src = Logs.Src.create "functoria" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

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

let package_names t = List.map Package.name (Info.packages t)

let app_info ?(runtime_package = "functoria-runtime") ?opam_list
    ?(gen_modname = "Info_gen") ?(modname = "Functoria_runtime") () =
  let file = Fpath.(v (String.Ascii.lowercase gen_modname) + "ml") in
  let module_name = gen_modname in
  let connect _ impl_name _ = Fmt.strf "return %s.info" impl_name in
  let files _ = [ file ] in
  let build i =
    Log.info (fun m -> m "Generating: %a (info)" Fpath.pp file);
    let packages =
      match opam_list with
      | None -> default_opam_deps (package_names i)
      | Some pkgs -> Action.ok (String.Map.of_list pkgs)
    in
    packages >>= fun opam ->
    let ocl = String.Set.of_list (Info.libraries i) in
    Fmt.kstr (Action.write_file file) "@[<v 2>let info = %a@]"
      (pp_dump_pkgs modname)
      (Info.name i, opam, ocl)
  in
  let packages = [ Package.v runtime_package ] in
  Impl.v ~packages ~connect ~build ~files module_name Info.t
