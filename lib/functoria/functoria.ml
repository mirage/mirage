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
module Key = Key
module Package = Package
module Info = Info
module Type = Type
module Impl = Impl
module Device = Device
module Install = Install
module Opam = Opam
module Lib = Lib
module Tool = Tool
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

(* Info device *)

let src = Logs.Src.create "functoria" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

let pp_packages fmt l =
  Fmt.pf fmt "[@ %a]"
    Fmt.(
      iter ~sep:(any ";@ ") List.iter @@ fun fmt (n, v) -> pf fmt "%S, %S" n v)
    l

let pp_info modname fmt name =
  Fmt.pf fmt "%s.{@ name = %S;@ libraries@]@ }" modname name

let dune_info_deps =
  {|
open Build_info.V1

let libraries = Statically_linked_libraries.to_list ()
let libraries =
  List.map (fun l ->
    let name = Statically_linked_library.name l in
    let version = match Statically_linked_library.version l with
      | None -> "n/a"
      | Some v -> Version.to_string v
    in
    name, version
  ) libraries
|}

let fixed_deps pkg =
  Fmt.str "@[<v 2>let libraries = %a@]@;" pp_packages (String.Map.bindings pkg)

let app_info ?(runtime_package = "functoria-runtime") ?build_info
    ?(gen_modname = "Info_gen") ?(modname = "Functoria_runtime") () =
  let info_gen = Fpath.(v (String.Ascii.lowercase gen_modname) + "ml") in
  let module_name = gen_modname in
  let connect _ impl_name _ = Fmt.str "return %s.info" impl_name in
  let configure i =
    Log.info (fun m -> m "Generating: %a (info)" Fpath.pp info_gen);
    let libraries =
      match build_info with
      | None -> dune_info_deps
      | Some pkgs -> fixed_deps (String.Map.of_list pkgs)
    in
    Fmt.kstr
      (Action.write_file info_gen)
      "%s@.@[<v 2>let info = %a@]" libraries (pp_info modname) (Info.name i)
  in
  let files _ = [ info_gen ] in
  let packages = Package.[ v runtime_package; v "dune-build-info" ] in
  Impl.v ~files ~packages ~connect ~configure module_name Info.t
