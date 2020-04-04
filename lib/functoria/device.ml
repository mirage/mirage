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
open Action.Infix

type abstract_key = Key.t

type package = Package.t

type info = Info.t

type 'a code = string

type ('a, 'impl) t = {
  (* static *)
  id : int;
  module_name : string;
  module_type : 'a Type.t;
  keys : abstract_key list;
  extra_deps : 'impl list;
  (* needed to build an [info] so needs to be an 'a value. *)
  packages : package list Key.value;
  (* dymamic *)
  connect : info -> string -> string list -> 'a code;
  dune : info -> Dune.stanza list Action.t;
  files : info -> Fpath.t list;
  build : info -> unit Action.t;
}

let pp : type a b. b Fmt.t -> (a, b) t Fmt.t =
 fun pp_impl ppf t ->
  let open Fmt.Dump in
  let fields =
    [
      field "id" (fun t -> t.id) Fmt.int;
      field "module_name" (fun t -> t.module_name) string;
      field "module_type" (fun t -> t.module_type) Type.pp;
      field "keys" (fun t -> t.keys) (list Key.pp);
      field "extra_deps" (fun t -> t.extra_deps) (list pp_impl);
    ]
  in
  record fields ppf t

let equal x y = x.id = y.id

let hash x = x.id

let default_connect _ _ l =
  Printf.sprintf "return (%s)" (String.concat ~sep:", " l)

let merge empty union a b =
  match (a, b) with
  | None, None -> Key.pure empty
  | Some a, None -> Key.pure a
  | None, Some b -> b
  | Some a, Some b -> Key.(pure union $ pure a $ b)

let merge_packages = merge [] List.append

let count =
  let i = ref 0 in
  fun () ->
    incr i;
    !i

let niet _ = Action.ok ()

let none _ = Action.ok []

let non _ = []

let v ?packages ?packages_v ?(keys = []) ?(extra_deps = [])
    ?(connect = default_connect) ?(dune = none) ?(files = non) ?(build = niet)
    module_name module_type =
  let packages = merge_packages packages packages_v in
  let id = count () in
  {
    module_type;
    id;
    module_name;
    keys;
    connect;
    packages;
    dune;
    files;
    build;
    extra_deps;
  }

let id t = t.id

let module_name t = t.module_name

let module_type t = t.module_type

let packages t = t.packages

let connect t = t.connect

let dune t = t.dune

let files t = t.files

let build t = t.build

let keys t = t.keys

let extra_deps t = t.extra_deps

let start impl_name args =
  Fmt.strf "@[%s.start@ %a@]" impl_name Fmt.(list ~sep:sp string) args

let extend ?packages ?packages_v ?(dune = none) ?(files = non)
    ?(pre_build = niet) ?(post_build = niet) t =
  let packages = merge_packages packages packages_v in
  let files i = files i @ t.files i in
  let build i =
    pre_build i >>= fun () ->
    t.build i >>= fun () -> post_build i
  in
  let dune i =
    dune i >>= fun x ->
    t.dune i >|= fun y -> x @ y
  in
  { t with packages; build; dune; files }
