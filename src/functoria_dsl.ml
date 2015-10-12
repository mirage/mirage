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
open Functoria_misc
open Rresult
module Key = Functoria_key

module Info = struct

  type t = {
    name: string;
    root: string;
    keys: Key.Set.t;
    keymap: Functoria_key.map;
    libraries: StringSet.t;
    packages: StringSet.t;
  }

  let name t = t.name
  let root t = t.root
  let libraries t = StringSet.elements t.libraries
  let packages t = StringSet.elements t.packages
  let keys t = t.keys
  let keymap t = t.keymap

  let create ?(keys=Key.Set.empty) ?(libraries=[]) ?(packages=[])
      ~keymap ~name ~root =
    let libraries = StringSet.of_list libraries in
    let packages = StringSet.of_list packages in
    { name; root; keys; libraries; packages; keymap}

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

  and any_impl = Any: _ impl -> any_impl

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
    method dependencies: any_impl list
  end

end = Typ

include Typ

let ($) f x = App { f; x }
let impl x = Impl x
let hidden x = Any x
let if_impl b x y = If(b,x,y)

let rec switch ~default l kv = match l with
  | [] -> default
  | (f, i) :: t -> If (Key.(pure ((=) f) $ kv), i, switch ~default t kv)

class base_configurable = object
  method libraries: string list Key.value = Key.pure []
  method packages: string list Key.value = Key.pure []
  method keys: Key.t list = []
  method connect (_:Info.t) (_:string) l =
    Printf.sprintf "return (`Ok (%s))" (String.concat ", " l)
  method configure (_: Info.t): (unit,string) R.t = R.ok ()
  method clean (_: Info.t): (unit,string) R.t = R.ok ()
  method dependencies: any_impl list = []
end

type job = JOB
let job = Type JOB

class ['ty] foreign
    ?(keys=[]) ?(libraries=[]) ?(packages=[]) ?(dependencies=[])
    module_name ty
  : ['ty] configurable
  =
  let name = Name.of_key module_name ~base:"f" in
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
    method dependencies = dependencies
  end

let foreign ?keys ?libraries ?packages ?dependencies module_name ty =
  Impl (new foreign ?keys ?libraries ?packages ?dependencies module_name ty)

(* {Misc} *)

let rec equal
  : type t1 t2. t1 impl -> t2 impl -> bool
  = fun x y -> match x, y with
    | Impl c, Impl c' ->
      c#name = c'#name
      && List.for_all2 equal_any c#dependencies c'#dependencies
    | App a, App b -> equal a.f b.f && equal a.x b.x
    | If (cond1, t1, e1), If (cond2, t2, e2) ->
      (* Key.value is a functional value (it contains a closure for eval).
         There is no prettier way than physical equality. *)
      cond1 == cond2 && equal t1 t2 && equal e1 e2
    | Impl _, (If _ | App _)
    | App _ , (If _ | Impl _)
    | If _  , (App _ | Impl _) -> false

and equal_any (Any x) (Any y) = equal x y

let rec hash: type t . t impl -> int = function
  | Impl c ->
    Hashtbl.hash
      (c#name, Hashtbl.hash c#keys, List.map hash_any c#dependencies)
  | App { f; x } -> Hashtbl.hash (`Bla (hash f, hash x))
  | If (cond, t, e) ->
    Hashtbl.hash (`If (cond, hash t, hash e))

and hash_any (Any x) = hash x

module ImplTbl = Hashtbl.Make (struct
    type t = any_impl
    let hash = hash_any
    let equal = equal_any
  end)

let explode x = match x with
  | Impl c -> `Impl c
  | App { f; x } -> `App (Any f, Any x)
  | If (cond, x, y) -> `If (cond, x, y)
