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
  pin : string option;
  build : bool;
  libs : String.Set.t;
  min : String.Set.t;
  max : String.Set.t;
}

let name t = t.name

let pin t = t.pin

let build_dependency t = t.build

let libraries t = String.Set.elements t.libs

let min_versions t = String.Set.elements t.min

let max_versions t = String.Set.elements t.max

let merge a b =
  if a.name <> b.name then None
  else
    let name = a.name in
    let libs = String.Set.union a.libs b.libs
    and min = String.Set.union a.min b.min
    and max = String.Set.union a.max b.max
    and pin =
      match (a.pin, b.pin) with
      | None, None -> None
      | None, Some a | Some a, None -> Some a
      | Some a, Some b when String.equal a b -> Some a
      | _ -> invalid_arg ("conflicting pin depends for " ^ name)
    and build = a.build || b.build in
    match pin with
    | None -> Some { name; build; libs; min; max; pin }
    | Some _ ->
        (* pin wins over min and max *)
        let empty = String.Set.empty in
        Some { name; build; libs; min = empty; max = empty; pin }

let v ?(build = false) ?sublibs ?libs ?min ?max ?pin name =
  let libs =
    match (sublibs, libs) with
    | None, None -> [ name ]
    | Some xs, None -> name :: List.map (fun x -> name ^ "." ^ x) xs
    | None, Some a -> a
    | Some _, Some _ ->
        Fmt.invalid_arg
          "dependent package %s may either specify ~sublibs or ~ocamlfind" name
  in
  let libs = String.Set.of_list libs in
  let to_set = function
    | None -> String.Set.empty
    | Some m -> String.Set.singleton m
  in
  let min = to_set min and max = to_set max in
  { name; build; libs; min; max; pin }

let exts_to_string ppf (min, max, build) =
  let bui = if build then "build & " else "" in
  let esc_prefix prefix e = Fmt.str "%s %S" prefix e in
  let min_strs = List.map (esc_prefix ">=") (String.Set.elements min)
  and max_strs = List.map (esc_prefix "<") (String.Set.elements max)
  and flat xs = String.concat ~sep:" & " xs in
  match (String.Set.is_empty min, String.Set.is_empty max) with
  | true, true -> if build then Fmt.string ppf " {build}"
  | false, true -> Fmt.pf ppf " {%s %s}" bui (flat min_strs)
  | true, false -> Fmt.pf ppf " {%s %s}" bui (flat max_strs)
  | false, false ->
      Fmt.pf ppf " {%s %s & %s}" bui (flat min_strs) (flat max_strs)

let pp ?(surround = "") ppf p =
  Fmt.pf ppf "%s%s%s%a" surround p.name surround exts_to_string
    (p.min, p.max, p.build)
