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
  config_file : Fpath.t;
  name : string;
  project_name : string;
  output : string option;
  keys : Key.Set.t;
  runtime_args : Runtime_arg.Set.t;
  context : Context.t;
  packages : Package.t String.Map.t;
  local_libs : string list;
  opam :
    extra_repo:(string * string) list ->
    install:Install.t ->
    opam_name:string ->
    Opam.t;
}

let name t = t.name
let project_name t = t.project_name
let config_file t = t.config_file

let main t =
  let main = match t.output with None -> "main" | Some f -> f in
  Fpath.v (main ^ ".ml")

let get t k = Key.get t.context k
let opam t = t.opam
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
let libraries t = libraries (packages t) @ t.local_libs

let pins packages =
  List.fold_left
    (fun acc p -> match Package.pin p with None -> acc | Some u -> u :: acc)
    [] packages

let keys t = Key.Set.elements t.keys
let runtime_args t = Runtime_arg.Set.elements t.runtime_args
let context t = t.context

let v ?(config_file = Fpath.v "config.ml") ~packages ~local_libs ~keys
    ~runtime_args ~context ?configure_cmd ?pre_build_cmd ?lock_location
    ~build_cmd ~src ~project_name name =
  let keys = Key.Set.of_list keys in
  let runtime_args = Runtime_arg.Set.of_list runtime_args in
  let opam ~extra_repo ~install ~opam_name =
    Opam.v ~depends:packages ~install ~pins:(pins packages) ~extra_repo
      ?configure:configure_cmd ?pre_build:pre_build_cmd ?lock_location
      ~build:build_cmd ~src ~opam_name name
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
            | None -> m))
      String.Map.empty packages
  in
  {
    config_file;
    name;
    project_name;
    keys;
    runtime_args;
    packages;
    local_libs;
    context;
    output = None;
    opam;
  }

let pp_packages ?(surround = "") ?sep ppf t =
  let pkgs = packages t in
  Fmt.pf ppf "%a" (Fmt.iter ?sep List.iter (Package.pp ~surround)) pkgs

let pp verbose ppf ({ name; keys; context; output; _ } as t) =
  let show ?(newline = true) name =
    Fmt.pf ppf ("@[<2>%-10s@ %a@]" ^^ if newline then "@," else "") name
  in
  let list = Fmt.iter ~sep:(Fmt.any ",@ ") List.iter Fmt.string in
  show "Name" Fmt.string name;
  show "Keys" ~newline:(verbose || output <> None) (Key.pps context) keys;
  let () =
    match output with
    | None -> ()
    | Some o -> show "Output" ~newline:verbose Fmt.(string) o
  in
  if verbose then show "Libraries " list (libraries t);
  if verbose then
    show "Packages" ~newline:false
      (pp_packages ?surround:None ~sep:(Fmt.any ",@ "))
      t

let t =
  let i =
    v ~config_file:(Fpath.v "config.ml") ~packages:[] ~local_libs:[] ~keys:[]
      ~runtime_args:[]
      ~build_cmd:(fun _ -> "dummy")
      ~context:Context.empty ~src:`None "dummy" ~project_name:"dummy"
  in
  Type.v i
