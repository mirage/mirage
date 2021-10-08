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

open Action.Syntax
open Astring

type abstract_key = Key.t

type package = Package.t

type info = Info.t

type 'a value = 'a Key.value

type 'a code = string

type ('a, 'impl) t = {
  id : 'a Typeid.t;
  module_name : string;
  module_type : 'a Type.t;
  keys : abstract_key list;
  packages : package list value;
  install : info -> Install.t value;
  connect : info -> string -> string list -> 'a code;
  dune : info -> Dune.stanza list;
  configure : info -> unit Action.t;
  files : (info -> Fpath.t list) option;
  extra_deps : 'impl list;
}

let pp : type a b. b Fmt.t -> (a, b) t Fmt.t =
 fun pp_impl ppf t ->
  let open Fmt.Dump in
  let fields =
    [
      field "id" (fun t -> t.id) Typeid.pp;
      field "module_name" (fun t -> t.module_name) string;
      field "module_type" (fun t -> t.module_type) Type.pp;
      field "keys" (fun t -> t.keys) (list Key.pp);
      field "install" (fun _ -> "<dyn>") Fmt.string;
      field "packages" (fun _ -> "<dyn>") Fmt.string;
      field "extra_deps" (fun t -> t.extra_deps) (list pp_impl);
    ]
  in
  record fields ppf t

let equal x y = Typeid.equal x.id y.id

let witness x y = Typeid.witness x.id y.id

let hash x = Typeid.id x.id

let default_connect _ _ l =
  Printf.sprintf "return (%s)" (String.concat ~sep:", " l)

let niet _ = Action.ok ()

let nil _ = []

let merge empty union a b =
  match (a, b) with
  | None, None -> Key.pure empty
  | Some a, None -> Key.pure a
  | None, Some b -> b
  | Some a, Some b -> Key.(pure union $ pure a $ b)

let merge_packages = merge [] List.append

let merge_install = merge Install.empty Install.union

let v ?packages ?packages_v ?install ?install_v ?(keys = []) ?(extra_deps = [])
    ?(connect = default_connect) ?(dune = nil) ?(configure = niet) ?files
    module_name module_type =
  let id = Typeid.gen () in
  let packages = merge_packages packages packages_v in
  let install i =
    let aux = function None -> None | Some f -> Some (f i) in
    merge_install (aux install) (aux install_v)
  in
  {
    module_type;
    id;
    module_name;
    keys;
    connect;
    packages;
    install;
    dune;
    configure;
    files;
    extra_deps;
  }

let id t = Typeid.id t.id

let module_name t = t.module_name

let module_type t = t.module_type

let packages t = t.packages

let install t = t.install

let connect t = t.connect

let configure t = t.configure

let files t i =
  let gen = Action.generated_files (t.configure i) in
  match t.files with
  | None -> gen
  | Some files -> Fpath.Set.(union gen (of_list (files i)))

let dune t = t.dune

let keys t = t.keys

let extra_deps t = t.extra_deps

let start impl_name args =
  Fmt.str "@[%s.start@ %a@]" impl_name Fmt.(list ~sep:sp string) args

let uniq t = Fpath.Set.(elements (of_list t))

let exec_hook i = function None -> Action.ok () | Some h -> h i

let extend ?packages ?packages_v ?dune ?pre_configure ?post_configure ?files t =
  let files =
    match (files, t.files) with
    | None, None -> None
    | Some f, None | None, Some f -> Some f
    | Some x, Some y -> Some (fun i -> uniq (x i @ y i))
  in
  let packages =
    Key.(pure List.append $ merge_packages packages packages_v $ t.packages)
  in
  let exec pre f post i =
    let* () = exec_hook i pre in
    let* () = f i in
    exec_hook i post
  in
  let configure = exec pre_configure t.configure post_configure in
  let dune =
    Option.map (fun dune i -> t.dune i @ dune i) dune
    |> Option.value ~default:t.dune
  in
  { t with packages; files; configure; dune }

let nice_name d =
  module_name d
  |> String.cuts ~sep:"."
  |> String.concat ~sep:"_"
  |> String.Ascii.lowercase
  |> Misc.Name.ocamlify

type ('a, 'i) device = ('a, 'i) t

module Graph = struct
  type t =
    | D : { dev : ('a, _) device; args : t list; deps : t list; id : int } -> t

  type dtree = t

  module IdTbl = Hashtbl.Make (struct
    type t = dtree

    let hash (D t) = t.id

    let equal (D t1) (D t2) = Int.equal t1.id t2.id
  end)

  (* We iter in *reversed* topological order. *)
  let fold f t z =
    let tbl = IdTbl.create 50 in
    let state = ref z in
    let rec aux v =
      if IdTbl.mem tbl v then ()
      else
        let (D { args; deps; _ }) = v in
        IdTbl.add tbl v ();
        List.iter aux deps;
        List.iter aux args;
        state := f v !state
    in
    aux t;
    !state

  let impl_name (D { dev; args = _; deps = _; id }) =
    match Type.is_functor (module_type dev) with
    | false -> module_name dev
    | true ->
        let prefix = Astring.String.Ascii.capitalize (nice_name dev) in
        Fmt.str "%s__%d" prefix id

  let var_name (D { dev; args = _; deps = _; id }) =
    let prefix = nice_name dev in
    Fmt.str "%s__%i" prefix id
end
