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
module Type = Functoria_type
module Impl = Functoria_impl
module Device = Functoria_device
module Install = Functoria_install

type 'a value = 'a Functoria_key.value

type info = Functoria_info.t

type package = Functoria_package.t

type 'a typ = 'a Functoria_type.t

type 'a impl = 'a Functoria_impl.t

type 'a device = ('a, Impl.abstract) Device.t

let package = Package.v

let ( @-> ) = Type.( @-> )

let typ = Type.v

let ( $ ) = Impl.( $ )

let of_device = Impl.of_device

let abstract = Impl.abstract

let if_impl = Impl.if_

let match_impl = Impl.match_

let pp_device ppf t = Device.pp Impl.pp_abstract ppf t

let impl ?packages ?packages_v ?install ?install_v ?keys ?extra_deps ?connect
    ?configure ?build ?clean module_name module_type =
  of_device
  @@ Device.v ?packages ?packages_v ?install ?install_v ?keys ?extra_deps
       ?connect ?configure ?build ?clean module_name module_type

let main ?packages ?packages_v ?keys ?extra_deps module_name ty =
  let connect _ = Device.start in
  impl ?packages ?packages_v ?keys ?extra_deps ~connect module_name ty

let foreign ?packages ?packages_v ?keys ?deps module_name ty =
  main ?packages ?packages_v ?keys ?extra_deps:deps module_name ty

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
    Info.v ~packages:[] ~keys:[] ~context:Key.empty_context ~build_cmd:[]
      ~build_dir:Fpath.(v "dummy")
      ~src:`None "dummy"
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
