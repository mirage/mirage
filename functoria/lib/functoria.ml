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
open Astring

open Misc

module Key = Key

type package = {
  opam : string ;
  pin : string option ;
  build : bool ;
  ocamlfind : String.Set.t ;
  min : String.Set.t ;
  max : String.Set.t ;
}

module Package = struct
  let merge opam a b =
    let ocamlfind = String.Set.union a.ocamlfind b.ocamlfind
    and min = String.Set.union a.min b.min
    and max = String.Set.union a.max b.max
    and pin =
      match a.pin, b.pin with
      | None, None -> None
      | None, Some a | Some a, None -> Some a
      | Some a, Some b when String.equal a b -> Some a
      | _ -> invalid_arg ("conflicting pin depends for " ^ opam)
    and build = a.build || b.build
    in
    match pin with
    | Some _ ->
      (* pin wins over min and max *)
      Some { opam ; build ; ocamlfind ; min = String.Set.empty ; max = String.Set.empty ; pin }
    | None ->
      Some { opam ; build ; ocamlfind ; min ; max ; pin }

  let package ?(build = false) ?sublibs ?ocamlfind ?min ?max ?pin opam =
    let ocamlfind = match sublibs, ocamlfind with
      | None, None -> [opam]
      | Some xs, None -> opam :: List.map (fun x -> opam ^ "." ^ x) xs
      | None, Some a -> a
      | Some _, Some _ ->
        invalid_arg ("dependent package " ^ opam ^ " may either specify ~sublibs or ~ocamlfind")
    in
    let ocamlfind = String.Set.of_list ocamlfind in
    let to_set = function None -> String.Set.empty | Some m -> String.Set.singleton m in
    let min = to_set min and max = to_set max in
    { opam ; build ; ocamlfind ; min ; max ; pin }

  let libraries ps =
    let ocamlfind p = if p.build then String.Set.empty else p.ocamlfind in
    String.Set.elements
      (List.fold_left String.Set.union String.Set.empty
         (List.map ocamlfind ps))

  let package_names ps =
    List.fold_left (fun acc p -> if p.build then acc else p.opam :: acc) [] ps

  let exts_to_string min max build =
    let bui = if build then "build & " else "" in
    let esc_prefix prefix e = Printf.sprintf "%s %S" prefix e in
    let min_strs = List.map (esc_prefix ">=") (String.Set.elements min)
    and max_strs = List.map (esc_prefix "<") (String.Set.elements max)
    and flat xs = String.concat ~sep:" & " xs
    in
    match String.Set.is_empty min, String.Set.is_empty max with
    | true, true -> if build then "{build}" else ""
    | false, true -> Printf.sprintf "{%s %s}" bui (flat min_strs)
    | true, false -> Printf.sprintf "{%s %s}" bui (flat max_strs)
    | false, false ->
      Printf.sprintf "{%s %s & %s}" bui (flat min_strs) (flat max_strs)

  let pp_package t ppf p =
    Fmt.pf ppf "%s%s%s %s" t p.opam t (exts_to_string p.min p.max p.build)
end

let package = Package.package

module Info = struct
  type t = {
    name: string;
    output: string option;
    build_dir: Fpath.t;
    keys: Key.Set.t;
    context: Key.context;
    packages: package String.Map.t;
  }

  let name t = t.name
  let build_dir t = t.build_dir
  let output t = t.output
  let with_output t output = { t with output = Some output }

  let packages t = List.map snd (String.Map.bindings t.packages)
  let libraries t = Package.libraries (packages t)
  let package_names t = Package.package_names (packages t)
  let pins t =
    List.fold_left
      (fun acc p -> match p.pin with None -> acc | Some u -> (p.opam, u) :: acc)
      [] (packages t)

  let keys t = Key.Set.elements t.keys
  let context t = t.context

  let create ~packages ~keys ~context ~name ~build_dir =
    let keys = Key.Set.of_list keys in
    let packages = List.fold_left (fun m p ->
        let n = p.opam in
        match String.Map.find p.opam m with
        | None -> String.Map.add n p m
        | Some p' -> match Package.merge p.opam p p' with
          | Some p -> String.Map.add n p m
          | None -> invalid_arg ("bad version constraints in " ^ p.opam))
        String.Map.empty packages
    in
    { name; build_dir; keys; packages; context; output = None }

  let pp_packages ?(surround = "") ?sep ppf t =
    Fmt.pf ppf "%a" (Fmt.iter ?sep List.iter (Package.pp_package surround)) (packages t)

  let pp verbose ppf ({ name ; build_dir ; keys ; context ; output; _ } as t) =
    let show name = Fmt.pf ppf "@[<2>%s@ %a@]@," name in
    let list = Fmt.iter ~sep:(Fmt.unit ",@ ") List.iter Fmt.string in
    show "Name      " Fmt.string name;
    show "Build-dir " Fpath.pp build_dir;
    show "Keys      " (Key.pps context) keys;
    show "Output    " Fmt.(option string) output;
    if verbose then show "Libraries " list (libraries t);
    if verbose then
      show "Packages  "
        (pp_packages ?surround:None ~sep:(Fmt.unit ",@ ")) t

  let opam ?name ppf t =
    let name = match name with None -> t.name | Some x -> x in
    Fmt.pf ppf "opam-version: \"2.0\"@." ;
    Fmt.pf ppf "name: \"%s\"@." name ;
    Fmt.pf ppf "depends: [ @[<hv>%a@]@ ]@."
      (pp_packages ~surround:"\"" ~sep:(Fmt.unit "@ ")) t ;
    match pins t with
    | [] -> ()
    | pin_depends ->
      let pp_pin ppf (package, url) =
        Fmt.pf ppf "[\"%s.dev\" %S]" package url
      in
      Fmt.pf ppf "pin-depends: [ @[<hv>%a@]@ ]@."
        Fmt.(list ~sep:(unit "@ ") pp_pin) pin_depends
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
    method packages: package list Key.value
    method connect: Info.t -> string -> string list -> string
    method configure: Info.t -> (unit, R.msg) R.t
    method build: Info.t -> (unit, R.msg) R.t
    method clean: Info.t -> (unit, R.msg) R.t
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

type key = Key.t
type context = Key.context
type 'a value = 'a Key.value
type job = JOB
let job = Type JOB

class base_configurable = object
  method packages: package list Key.value = Key.pure []
  method keys: Key.t list = []
  method connect (_:Info.t) (_:string) l =
    Printf.sprintf "return (%s)" (String.concat ~sep:", " l)
  method configure (_: Info.t): (unit, R.msg) R.t = R.ok ()
  method build (_: Info.t): (unit, R.msg) R.t = R.ok ()
  method clean (_: Info.t): (unit, R.msg) R.t = R.ok ()
  method deps: abstract_impl list = []
end

class ['ty] foreign
     ?(packages=[]) ?(keys=[]) ?(deps=[]) module_name ty
  : ['ty] configurable
  =
  let name = Name.create module_name ~prefix:"f" in
  object
    method ty = ty
    method name = name
    method module_name = module_name
    method keys = keys
    method packages = Key.pure packages
    method connect _ modname args =
      Fmt.strf
        "@[%s.start@ %a@]"
        modname
        Fmt.(list ~sep:sp string)  args
    method clean _ = R.ok ()
    method configure _ = R.ok ()
    method build _ = R.ok ()
    method deps = deps
  end

let foreign ?packages ?keys ?deps module_name ty =
  Impl (new foreign ?packages ?keys ?deps module_name ty)

(* {Misc} *)

let rec equal
  : type t1 t2. t1 impl -> t2 impl -> bool
  = fun x y -> match x, y with
    | Impl c, Impl c' ->
      c#name = c'#name
      && List.for_all2 Key.equal c#keys c'#keys
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

module type KEY =
  module type of Key
  with type 'a Arg.converter = 'a Key.Arg.converter
   and type 'a Arg.t = 'a Key.Arg.t
   and type Arg.info = Key.Arg.info
   and type 'a value = 'a Key.value
   and type 'a key = 'a Key.key
   and type t = Key.t
   and type Set.t = Key.Set.t
   and type 'a Alias.t = 'a Key.Alias.t
   and type context = Key.context

module Misc = Misc
