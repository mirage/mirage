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

open Cmdliner

module Arg = struct
  (** {1 Arguments} *)

  let info = Arg.info

  type 'a kind =
    | Opt : 'a * 'a Arg.conv -> 'a kind
    | Opt_all : 'a Arg.conv -> 'a list kind
    | Required : 'a Arg.conv -> 'a option kind
    | Flag : bool kind

  let pp_conv c = Arg.conv_printer c

  let pp_kind : type a. a kind -> a Fmt.t = function
    | Opt (_, c) -> pp_conv c
    | Opt_all c -> pp_conv (Arg.list c)
    | Required c -> pp_conv (Arg.some c)
    | Flag -> Fmt.bool

  let compare_kind : type a b. a kind -> b kind -> int =
   fun a b ->
    let default cx x = Fmt.to_to_string (Arg.conv_printer cx) x in
    match (a, b) with
    | Opt (x, cx), Opt (y, cy) -> String.compare (default cx x) (default cy y)
    | Required _, Required _ -> 0
    | Opt_all _, Opt_all _ -> 0
    | Flag, Flag -> 0
    | Opt _, _ -> 1
    | _, Opt _ -> -1
    | Required _, _ -> 1
    | _, Required _ -> -1
    | Opt_all _, _ -> 1
    | _, Opt_all _ -> -1

  type 'a t = { info : Arg.info; kind : 'a kind }

  let pp t = pp_kind t.kind
  let equal x y = compare_kind x.kind y.kind = 0
  let opt conv default info = { info; kind = Opt (default, conv) }
  let flag info = { info; kind = Flag }
  let required conv info = { info; kind = Required conv }
  let opt_all conv info = { info; kind = Opt_all conv }

  let default (type a) (t : a t) =
    match t.kind with
    | Opt (d, _) -> d
    | Flag -> (false : bool)
    | Required _ -> (None : _ option)
    | Opt_all _ -> ([] : _ list)

  let make_opt_cmdliner wrap i default desc =
    Arg.(wrap @@ opt (some' ?none:default desc) None i)

  let make_opt_all_cmdliner wrap i desc = Arg.(wrap @@ opt_all desc [] i)

  (* Wrap terms into an ['a option] to distinguish between default
     and absent values. *)
  let to_cmdliner (type a) (t : a t) : a option Cmdliner.Term.t =
    let i = t.info in
    match t.kind with
    | Flag -> Arg.(value & vflag None [ (Some true, i) ])
    | Opt (default, desc) -> make_opt_cmdliner Arg.value i (Some default) desc
    | Required desc ->
        make_opt_cmdliner Arg.required i None (Arg.some (Arg.some desc))
    | Opt_all desc ->
        let list_to_option = function
          | [] -> None
          | _ :: _ as lst -> Some lst
        in
        let wrap arg = Term.(const list_to_option $ Arg.value arg) in
        make_opt_all_cmdliner wrap i desc
end

type 'a key = { name : string; arg : 'a Arg.t; key : 'a Context.key }
type t = Any : 'a key -> t

let equal (Any x) (Any y) = String.equal x.name y.name && Arg.equal x.arg y.arg

(* Set of keys, without runtime name conflicts. This is useful to create a
   valid cmdliner term. *)
module Names = Stdlib.Set.Make (struct
  type nonrec t = t

  let compare (Any x) (Any y) = String.compare x.name y.name
end)

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

let v x = Any x
let name (Any k) = k.name

(* Key Map *)

type context = Context.t

let add_to_context t = Context.add t.key
let find (type a) ctx (t : a key) : a option = Context.find t.key ctx
let get ctx t = match find ctx t with Some x -> x | None -> Arg.default t.arg
let mem_u ctx t = Context.mem t.key ctx

(* {2 Values} *)

type +'a value = { deps : Set.t; v : context -> 'a }

let eval p v = v.v p
let pure x = { deps = Set.empty; v = (fun _ -> x) }

let app f x =
  { deps = Set.union f.deps x.deps; v = (fun p -> (eval p f) (eval p x)) }

let map f x = app (pure f) x
let pipe x f = map f x
let if_ c t e = pipe c @@ fun b -> if b then t else e
let match_ v f = map f v
let ( $ ) = app

let value k =
  let v c = get c k in
  { deps = Set.singleton (Any k); v }

let of_deps deps = { (pure ()) with deps }
let deps k = k.deps
let mem p v = Set.for_all (function Any x -> mem_u p x) v.deps
let peek p v = if mem p v then Some (eval p v) else None
let default v = eval Context.empty v

(* {2 Pretty printing} *)

let pp = Set.pp_elt
let pp_deps fmt v = Set.pp fmt v.deps

let pps p ppf l =
  let pp' fmt k v =
    let default = if mem_u p k then Fmt.nop else Fmt.any " (default)" in
    Fmt.pf fmt "%a=%a%a"
      Fmt.(styled `Bold string)
      k.name (Arg.pp k.arg) v default ()
  in
  let f fmt (Any k) =
    match (k.arg.Arg.kind, get p k) with
    | Arg.Required _, None -> Fmt.(styled `Bold string) fmt k.name
    | Arg.Opt _, v -> pp' fmt k v
    | Arg.Required _, v -> pp' fmt k v
    | Arg.Flag, v -> pp' fmt k v
    | Arg.Opt_all _, v -> pp' fmt k v
    (* Warning 4 and GADT don't interact well. *)
  in
  let pp = Fmt.vbox @@ fun ppf s -> Set.(pp_gen f ppf @@ s) in
  pp ppf l

(* {2 Key creation} *)

(* Unexposed smart constructor. *)
let make ~arg ~name =
  let key = Context.new_key name in
  { arg; name; key }

let create name arg =
  if name = "" then
    invalid_arg "Key.create: key name cannot be the empty string";
  make ~arg ~name

(* {2 Cmdliner interface} *)

let context l =
  let names = Names.of_list (Set.elements l) in
  let gather (Any k) rest =
    let f v p = match v with None -> p | Some v -> Context.add k.key v p in
    let key = Arg.to_cmdliner k.arg in
    match k.arg.Arg.kind with
    | Arg.Opt _ -> Cmdliner.Term.(const f $ key $ rest)
    | Arg.Required _ -> Cmdliner.Term.(const f $ key $ rest)
    | Arg.Flag -> Cmdliner.Term.(const f $ key $ rest)
    | Arg.Opt_all _ -> Cmdliner.Term.(const f $ key $ rest)
  in
  Names.fold gather names (Cmdliner.Term.const Context.empty)
