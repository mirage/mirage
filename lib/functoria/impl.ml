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

let src = Logs.Src.create "functoria" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

type _ t =
  | Dev : 'ty device -> 'ty t (* base devices *)
  | App : ('a, 'b) app -> 'b t (* functor application *)
  | If : bool Key.value * 'a t * 'a t -> 'a t

and ('a, 'b) app = { f (* functor *) : ('a -> 'b) t; x (* parameter *) : 'a t }

and 'a device = ('a, abstract) Device.t

and abstract = Abstract : _ t -> abstract

let abstract t = Abstract t

let of_device v = Dev v

let if_ b x y = If (b, x, y)

let rec match_ kv ~default = function
  | [] -> default
  | (f, i) :: t -> If (Key.(pure (( = ) f) $ kv), i, match_ kv ~default t)

let ( $ ) f x = App { f; x }

let v ?packages ?packages_v ?keys ?extra_deps ?connect ?dune ?files ?build
    module_name module_type =
  of_device
  @@ Device.v ?packages ?packages_v ?keys ?extra_deps ?connect ?dune ?files
       ?build module_name module_type

let main ?packages ?packages_v ?keys ?extra_deps module_name ty =
  let connect _ = Device.start in
  v ?packages ?packages_v ?keys ?extra_deps ~connect module_name ty

let rec pp : type a. a t Fmt.t =
 fun ppf -> function
  | Dev d -> Fmt.pf ppf "Dev %a" (Device.pp pp_abstract) d
  | App a -> Fmt.pf ppf "App %a" pp_app a
  | If (_, x, y) -> Fmt.pf ppf "If (_,%a,%a)" pp x pp y

and pp_app : type a b. (a, b) app Fmt.t =
 fun ppf t -> Fmt.pf ppf "{@[ f: %a;@, x: %a @]}" pp t.f pp t.x

and pp_abstract ppf (Abstract i) = pp ppf i

let rec hash : type a. a t -> int = function
  | Dev c -> Device.hash c
  | App { f; x } -> Hashtbl.hash (hash f, hash x)
  | If (cond, t, e) -> Hashtbl.hash (cond, hash t, hash e)

let hash_abstract (Abstract x) = hash x

let rec equal : type t1 t2. t1 t -> t2 t -> bool =
 fun x y ->
  match (x, y) with
  | Dev c, Dev c' -> Device.equal c c'
  | App a, App b -> equal a.f b.f && equal a.x b.x
  | If (cond1, t1, e1), If (cond2, t2, e2) ->
      (* Key.value is a functional value (it contains a closure for eval).
         There is no prettier way than physical equality. *)
      cond1 == cond2 && equal t1 t2 && equal e1 e2
  | _ -> false

let equal_abtract (Abstract a) (Abstract b) = equal a b

module Tbl = Hashtbl.Make (struct
  type t = abstract

  let hash = hash_abstract

  let equal = equal_abtract
end)

type 'b f_dev = { f : 'a. ('a, abstract) Device.t -> 'b }

type 'a f_if = cond:bool Key.value -> then_:'a -> else_:'a -> 'a

type 'a f_app = f:'a -> x:'a -> 'a

let with_left_most_device ctx t { f } =
  let rec aux : type a. a t -> _ = function
    | Dev d -> f d
    | App a -> aux a.f
    | If (b, x, y) -> if Key.eval ctx b then aux x else aux y
  in
  aux t

let map (type r) ~if_ ~app ~dev t =
  let tbl = Tbl.create 50 in
  let rec aux : type a. a t -> r =
   fun impl ->
    if Tbl.mem tbl @@ abstract impl then Tbl.find tbl (abstract impl)
    else
      let acc =
        match impl with
        | Dev d ->
            let deps =
              List.fold_right
                (fun (Abstract x) l -> aux x :: l)
                (Device.extra_deps d) []
            in
            dev.f d ~deps
        | App a ->
            let f = aux a.f in
            let x = aux a.x in
            app ~f ~x
        | If (cond, then_, else_) ->
            let then_ = aux then_ in
            let else_ = aux else_ in
            if_ ~cond ~then_ ~else_
      in
      Tbl.add tbl (abstract impl) acc;
      acc
  in
  aux t
