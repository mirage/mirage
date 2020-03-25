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

type 'a key = { name : string; put : 'a -> exn; get : exn -> 'a }

let new_key (type a) name =
  let module M = struct
    exception E of a
  end in
  let put a = M.E a in
  let get = function
    | M.E a -> a
    | _ -> raise @@ Invalid_argument ("duplicate key: " ^ name)
  in
  { name; put; get }

module Map = Map.Make (String)

type t = exn Map.t

let empty = Map.empty

let add k v (t : t) : t = Map.add k.name (k.put v) t

let mem k (t : t) = Map.mem k.name t

let find k (t : t) =
  if Map.mem k.name t then Some (k.get @@ Map.find k.name t) else None

let dump : t Fmt.t =
  let pp_elt ppf (k, v) = Fmt.pf ppf "[%s: %a]" k Fmt.exn v in
  let map_iter f = Map.iter (fun k v -> f (k, v)) in
  Fmt.box ~indent:2 @@ Fmt.(iter ~sep:(unit "@ ")) map_iter pp_elt

let merge ~default m =
  let aux _ _ v = Some v in
  Map.union aux default m
