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
  keys : Key.Set.t;
  context : Key.context;
  packages : Package.t String.Map.t;
  opam : Opam.t;
}

let name t = t.name

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

let libraries t = libraries (packages t)

let pins packages =
  List.fold_left
    (fun acc p ->
      match Package.pin p with
      | None -> acc
      | Some u -> (Package.name p, u) :: acc)
    [] packages

let keys t = Key.Set.elements t.keys

let context t = t.context

let v ~packages ~keys ~context ~build_cmd ~src name =
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
  { name; keys; packages; context; output = None; opam }

let pp_packages ?(surround = "") ?sep ppf t =
  Fmt.pf ppf "%a" (Fmt.iter ?sep List.iter (Package.pp ~surround)) (packages t)

let pp verbose ppf ({ name; keys; context; output; _ } as t) =
  let show ?(newline = true) name =
    Fmt.pf ppf ("@[<2>%-10s@ %a@]" ^^ if newline then "@," else "") name
  in
  let list = Fmt.iter ~sep:(Fmt.unit ",@ ") List.iter Fmt.string in
  show "Name" Fmt.string name;
  show "Keys" ~newline:(verbose && output <> None) (Key.pps context) keys;
  let () =
    match output with
    | None -> ()
    | Some o -> show "Output" ~newline:verbose Fmt.(string) o
  in
  if verbose then show "Libraries " list (libraries t);
  if verbose then
    show "Packages" ~newline:false
      (pp_packages ?surround:None ~sep:(Fmt.unit ",@ "))
      t

(* Device *)

let t =
  let i =
    v ~packages:[] ~keys:[] ~context:Key.empty_context ~build_cmd:[] ~src:`None
      "dummy"
  in
  Type.v i
