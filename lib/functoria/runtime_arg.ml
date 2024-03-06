(*
 * Copyright (c) 2023 Thomas Gazagnaire <thomas@gazagnaire.org>
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

open Misc

type 'a arg = { name : string; code : string; packages : Package.t list }
type t = Any : 'a arg -> t

(* Set of keys, where keys with the same name but with different
   defaults are distinguished. This is useful to build the graph of
   devices. *)
module Set = struct
  module M = struct
    type nonrec t = t

    let compare = compare
  end

  include Set.Make (M)

  let add k set =
    if mem k set then
      if k != find k set then
        match k with Any k -> Fmt.invalid_arg "Duplicate key name: %s" k.name
      else set
    else add k set

  let pp_gen = Fmt.iter ~sep:(Fmt.any ",@ ") iter
  let pp_elt fmt (Any k) = Fmt.string fmt k.name
  let pp = pp_gen pp_elt
end

let create ?name ?(packages = []) code =
  let name = match name with None -> Name.ocamlify code | Some n -> n in
  { name; packages; code }

let v k = Any k
let packages (Any k) = k.packages

(* {2 Code emission} *)

let module_name = "Key_gen"
let ocaml_name k = String.lowercase_ascii (Name.ocamlify k)

let serialize fmt (Any k) =
  Format.fprintf fmt "@[<2>let %s =@ @[Functoria_runtime.register@ %s@]@]@,"
    (ocaml_name k.name) k.code

let call fmt k = Fmt.pf fmt "(%s.%s ())" module_name (ocaml_name k.name)
