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
open Functoria_misc

module Key = Functoria_key

module Info = struct

  type t = {
    name: string;
    root: string;
    keys: Key.Set.t;
    context: Key.context;
    libraries: String.Set.t;
    packages: String.Set.t;
  }

  let name t = t.name
  let root t = t.root
  let libraries t = String.Set.elements t.libraries
  let packages t = String.Set.elements t.packages
  let keys t = Key.Set.elements t.keys
  let context t = t.context

  let create ?(packages=[]) ?(libraries=[]) ?(keys=[]) ~context ~name ~root =
    let libraries = String.Set.of_list libraries in
    let packages = String.Set.of_list packages in
    let keys = Key.Set.of_list keys in
    { name; root; keys; libraries; packages; context }

  let pp verbose ppf { name ; root ; keys ; context ; libraries ; packages } =
    let show name = Fmt.pf ppf "@[<2>%a@ %a@]@," Log.blue name in
    let set = Fmt.iter ~sep:(Fmt.unit ",@ ") String.Set.iter Fmt.string in
    show "Name      " Fmt.string name;
    show "Root      " Fmt.string root;
    show "Keys      " (Key.pps context) keys;
    if verbose then show "Libraries " set libraries;
    if verbose then show "Packages  " set packages

end

type _ typ =
  | Type: 'a -> 'a typ
  | Function: 'a typ * 'b typ -> ('a -> 'b) typ

let (@->) f t = Function (f, t)

let typ ty = Type ty

module rec Typ: sig

  type _ impl =
    | Impl: 'ty Typ.configurable -> 'ty impl (* base implementation *)
    | App: ('a, 'b) app -> 'b impl   (* functor application *)
    | If: bool Key.value * 'a impl * 'a impl -> 'a impl

  and ('a, 'b) app = {
    f: ('a -> 'b) impl;  (* functor *)
    x: 'a impl;          (* parameter *)
  }

  and abstract_impl = Abstract: _ impl -> abstract_impl

  class type ['ty] configurable = object
    method ty: 'ty typ
    method name: string
    method module_name: string
    method keys: Key.t list
    method packages: string list Key.value
    method libraries: string list Key.value
    method connect: Info.t -> string -> string list -> string
    method configure: Info.t -> (unit, string) R.t
    method clean: Info.t -> (unit, string) R.t
    method deps: abstract_impl list
  end

end = Typ

include Typ

let ($) f x = App { f; x }
let impl x = Impl x
let abstract x = Abstract x
let if_impl b x y = If(b,x,y)

let rec match_impl kv ~default = function
  | [] -> default
  | (f, i) :: t -> If (Key.(pure ((=) f) $ kv), i, match_impl kv ~default t)

class base_configurable = object
  method libraries: string list Key.value = Key.pure []
  method packages: string list Key.value = Key.pure []
  method keys: Key.t list = []
  method connect (_:Info.t) (_:string) l =
    Printf.sprintf "return (`Ok (%s))" (String.concat ", " l)
  method configure (_: Info.t): (unit,string) R.t = R.ok ()
  method clean (_: Info.t): (unit,string) R.t = R.ok ()
  method deps: abstract_impl list = []
end

type job = JOB
let job = Type JOB

class ['ty] foreign
     ?(packages=[]) ?(libraries=[]) ?(keys=[]) ?(deps=[]) module_name ty
  : ['ty] configurable
  =
  let name = Name.create module_name ~prefix:"f" in
  object
    method ty = ty
    method name = name
    method module_name = module_name
    method keys = keys
    method libraries = Key.pure libraries
    method packages = Key.pure packages
    method connect _ modname args =
      Fmt.strf
        "@[%s.start@ %a@ >>= fun t -> Lwt.return (`Ok t)@]"
        modname
        Fmt.(list ~sep:sp string)  args
    method clean _ = R.ok ()
    method configure _ = R.ok ()
    method deps = deps
  end

let foreign ?packages ?libraries ?keys ?deps module_name ty =
  Impl (new foreign ?packages ?libraries ?keys ?deps module_name ty)

(* {Misc} *)

let rec equal
  : type t1 t2. t1 impl -> t2 impl -> bool
  = fun x y -> match x, y with
    | Impl c, Impl c' ->
      c#name = c'#name
      && List.for_all2 equal_any c#deps c'#deps
    | App a, App b -> equal a.f b.f && equal a.x b.x
    | If (cond1, t1, e1), If (cond2, t2, e2) ->
      (* Key.value is a functional value (it contains a closure for eval).
         There is no prettier way than physical equality. *)
      cond1 == cond2 && equal t1 t2 && equal e1 e2
    | Impl _, (If _ | App _)
    | App _ , (If _ | Impl _)
    | If _  , (App _ | Impl _) -> false

and equal_any (Abstract x) (Abstract y) = equal x y

let rec hash: type t . t impl -> int = function
  | Impl c ->
    Hashtbl.hash
      (c#name, Hashtbl.hash c#keys, List.map hash_any c#deps)
  | App { f; x } -> Hashtbl.hash (`Bla (hash f, hash x))
  | If (cond, t, e) ->
    Hashtbl.hash (`If (cond, hash t, hash e))

and hash_any (Abstract x) = hash x

module ImplTbl = Hashtbl.Make (struct
    type t = abstract_impl
    let hash = hash_any
    let equal = equal_any
  end)

let explode x = match x with
  | Impl c -> `Impl c
  | App { f; x } -> `App (Abstract f, Abstract x)
  | If (cond, x, y) -> `If (cond, x, y)

type key = Functoria_key.t
type context = Functoria_key.context
type 'a value = 'a Functoria_key.value

module type KEY = module type of struct include Functoria_key end
