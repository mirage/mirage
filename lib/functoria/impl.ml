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

type 'a t =
  | If : {
      cond : 't Key.value;
      branches : ('t * 'a t) list;
      default : 'a t;
    }
      -> 'a t
  | Dev : { dev : 'a device; args : ('a, 'v) tl; deps : abstract list } -> 'v t
  | App : { f : 'a t; args : ('a, 'v) tl } -> 'v t

and abstract = Abstract : _ t -> abstract

and ('a, 'b) tl =
  | Nil : ('a, 'a) tl
  | Cons : 'a t * ('b, 'c) tl -> ('a -> 'b, 'c) tl

and 'a device = ('a, abstract) Device.t

(** Constructors *)

let abstract t = Abstract t

let rec app_has_no_arguments : type a. a t -> bool = function
  | App { f = _; args = Cons _ } -> false
  | App { f; args = Nil } -> app_has_no_arguments f
  | Dev { args = Nil; deps = []; dev } ->
      (* special hack for Job.noop *)
      if not (String.equal (Device.module_name dev) "Unit") then
        match Device.runtime_args dev with [] -> true | _ -> false
      else false
  | Dev _ -> false
  | If { cond = _; branches; default } ->
      app_has_no_arguments default
      || List.exists (fun (_, branch) -> app_has_no_arguments branch) branches

(* Devices *)

let mk_dev ~args ~deps dev = Dev { dev; args; deps }
let of_device dev = mk_dev ~args:Nil ~deps:(Device.extra_deps dev) dev

let v ?packages ?packages_v ?runtime_args ?keys ?extra_deps ?connect ?dune
    ?configure ?files module_name module_type =
  of_device
  @@ Device.v ?packages ?packages_v ?runtime_args ?keys ?extra_deps ?connect
       ?dune ?configure ?files module_name module_type

let main ?pos ?packages ?packages_v ?runtime_args ?keys ?extra_deps module_name
    ty =
  let connect _ = Device.start ?pos in
  v ?packages ?packages_v ?runtime_args ?keys ?extra_deps ~connect module_name
    ty

(* If *)

let mk_switch ~cond ~branches ~default = If { cond; branches; default }

let if_ cond then_ else_ =
  mk_switch ~cond ~branches:[ (true, then_); (false, else_) ] ~default:then_

let match_ cond ~default branches = mk_switch ~cond ~branches ~default

(* App *)

let rec concat_tl : type a b c. (a, b) tl -> (b, c) tl -> (a, c) tl =
 fun t1 t2 -> match t1 with Nil -> t2 | Cons (h, t) -> Cons (h, concat_tl t t2)

let rec mk_app : type a v. f:a t -> args:(a, v) tl -> v t =
 fun ~f ~args:args1 ->
  match f with
  | Dev { dev; args = args2; deps } ->
      mk_dev ~args:(concat_tl args2 args1) ~deps dev
  | App { f; args = args2 } -> mk_app ~f ~args:(concat_tl args2 args1)
  | _ -> App { f; args = args1 }

let ( $ ) f x = mk_app ~f ~args:(Cons (x, Nil))

(** Utilities *)

let rec pp : type a. a t Fmt.t =
 fun ppf -> function
  | Dev { dev; args; deps = _ } ->
      Fmt.pf ppf "@[<v>@[Dev %a@]@,@[<v2>args=[%a]@]@]" (Device.pp pp_abstract)
        dev pp_tl args
  | App { f; args } -> Fmt.pf ppf "App %a(%a)" pp f pp_tl args
  | If { cond = _; branches; default } ->
      Fmt.pf ppf "Switch (_,%a,%a)" (Fmt.list pp) (List.map snd branches) pp
        default

and pp_tl : type a b. (a, b) tl Fmt.t =
 fun ppf -> function
  | Nil -> ()
  | Cons (h, t) -> Fmt.pf ppf "%a,@ %a" pp h pp_tl t

and pp_abstract ppf (Abstract i) = pp ppf i

(** Tables and traversals *)

(* **** WARNING ******

   The [impl] type forms a DAG, implemented as terms with sharing.

   It is *essential* to preserve sharing while walking the terms.
   Otherwise
   - We risk double initialization of devices
   - The DOT graph is a mess
   - We might collect information twice

   As such, the equality, hashing, and tables must be tuned to share
   [impl]s appropriately and the various traversals must use appropriate tables.
*)

let rec hash : type a. a t -> int = function
  | Dev { dev; args; deps } ->
      Hashtbl.hash
        (`Dev, Device.hash dev, hash_tl args, List.map hash_abstract deps)
  | App { f; args } -> Hashtbl.hash (`App, hash f, hash_tl args)
  | If { cond; branches; default } ->
      Hashtbl.hash
        ( `If,
          cond,
          List.map (fun (p, t) -> Hashtbl.hash (p, hash t)) branches,
          hash default )

and hash_abstract (Abstract x) = hash x

and hash_tl : type a v. (a, v) tl -> int =
 fun x ->
  match x with
  | Nil -> Hashtbl.hash `Nil
  | Cons (h, t) -> Hashtbl.hash (`Cons, hash h, hash_tl t)

type ex = Ex : 'a -> ex

let equal_list p l1 l2 =
  List.length l1 = List.length l2 && List.for_all2 p l1 l2

let rec equal : type t1 t2. t1 t -> t2 t -> (t1, t2) Typeid.witness =
 fun x y ->
  match (x, y) with
  | Dev c, Dev c' -> (
      match
        ( equal_list equal_abstract c.deps c'.deps,
          equal_tl c.args c'.args (Device.witness c.dev c'.dev) )
      with
      | true, Eq -> Eq
      | _ -> NotEq)
  | App a, App b -> (
      match equal_tl a.args b.args (equal a.f b.f) with
      | Eq -> Eq
      | NotEq -> NotEq)
  | If x1, If x2 -> (
      match
        ( equal x1.default x2.default,
          Obj.repr x1.cond == Obj.repr x2.cond,
          equal_list
            (fun (p1, t1) (p2, t2) ->
              Ex p1 = Ex p2 && equal_abstract (abstract t1) (abstract t2))
            x1.branches x2.branches )
      with
      | Eq, true, true -> Eq
      | _ -> NotEq)
  | _ -> NotEq

and equal_abstract (Abstract x) (Abstract y) = Typeid.to_bool @@ equal x y

and equal_tl : type t1 t2 v1 v2.
    (t1, v1) tl ->
    (t2, v2) tl ->
    (t1, t2) Typeid.witness ->
    (v1, v2) Typeid.witness =
 fun x y eq ->
  match (x, y, eq) with
  | Nil, Nil, Eq -> Eq
  | Cons (h1, t1), Cons (h2, t2), Eq -> (
      match (equal h1 h2, equal_tl t1 t2 Eq) with Eq, Eq -> Eq | _ -> NotEq)
  | _ -> NotEq

module Tbl = Hashtbl.Make (struct
  type t = abstract

  let hash = hash_abstract
  let equal = equal_abstract
end)

module Hashcons : sig
  type tbl

  val create : unit -> tbl
  val add : tbl -> 'a t -> 'a t -> unit
  val get : tbl -> 'a t -> 'a t option
end = struct
  type tbl = abstract Tbl.t

  let create () = Tbl.create 50
  let add tbl a b = Tbl.add tbl (abstract a) (abstract b)

  let get (type a) tbl (oldv : a t) : a t option =
    if Tbl.mem tbl @@ abstract oldv then
      let (Abstract newv) = Tbl.find tbl (abstract oldv) in
      match equal oldv newv with Eq -> Some newv | NotEq -> None
    else None
end

let simplify ~full ~context (Abstract t) =
  let tbl = Hashcons.create () in
  let rec aux : type a. a t -> a t =
   fun impl ->
    match Hashcons.get tbl impl with
    | Some impl' -> impl'
    | None ->
        let acc =
          match impl with
          | If { cond; branches; default } ->
              (* Either
                 - A key is present in the context
                 - We are in full mode, and we use its default value
              *)
              if full || Key.mem context cond then
                let path = Key.eval context cond in
                let t =
                  try List.assoc path branches with Not_found -> default
                in
                aux t
              else
                let branches = List.map (fun (p, t) -> (p, aux t)) branches in
                mk_switch ~cond ~branches ~default
          | Dev { dev; args; deps } ->
              let args = aux_tl args in
              let deps = List.map aux_abstract deps in
              mk_dev ~args ~deps dev
          | App { f; args } ->
              let f = aux f in
              let args = aux_tl args in
              mk_app ~f ~args
        in
        Hashcons.add tbl impl acc;
        acc
  and aux_abstract (Abstract a) = Abstract (aux a)
  and aux_tl : type a v. (a, v) tl -> (a, v) tl = function
    | Nil -> Nil
    | Cons (h, t) -> Cons (aux h, aux_tl t)
  in
  Abstract (aux t)

let eval ~context (Abstract t) =
  let new_id =
    let r = ref 0 in
    fun () ->
      incr r;
      !r
  in
  let tbl = Tbl.create 50 in
  let rec aux : type a. a t -> Device.Graph.t =
   fun impl ->
    if Tbl.mem tbl @@ abstract impl then Tbl.find tbl (abstract impl)
    else
      let acc =
        match impl with
        | Dev { dev; args; deps } ->
            let args = aux_tl args in
            let deps = List.map aux_abstract deps in
            Device.Graph.D { dev; args; deps; id = new_id () }
        | App { f; args = extra_args } ->
            let (D { dev; args; deps; id = _ }) = aux f in
            let extra_args = aux_tl extra_args in
            D { dev; args = args @ extra_args; deps; id = new_id () }
        | If { cond; branches; default } ->
            let path = Key.eval context cond in
            let t = try List.assoc path branches with Not_found -> default in
            aux t
      in
      Tbl.add tbl (abstract impl) acc;
      acc
  and aux_abstract (Abstract a) = aux a
  and aux_tl : type a v. (a, v) tl -> _ = function
    | Nil -> []
    | Cons (h, t) ->
        let a = aux h in
        a :: aux_tl t
  in
  aux t

type 'b f_dev = { f : 'a. ('a, abstract) Device.t -> 'b }

let with_left_most_device ctx t (f : _ f_dev) =
  let rec aux : type a. a t -> _ = function
    | Dev d -> f.f d.dev
    | App a -> aux a.f
    | If { cond; branches; default } ->
        let path = Key.eval ctx cond in
        let t = try List.assoc path branches with Not_found -> default in
        aux t
  in
  aux t

type 'b f_dev_full = {
  f : 'a 'v. args:'b list -> deps:'b list -> 'a device -> 'b;
}

type 'a f_switch = {
  if_ : 'r. cond:'r Key.value -> branches:('r * 'a) list -> default:'a -> 'a;
}

type 'a f_app = f:'a -> args:'a list -> 'a

let map (type r) ~(mk_switch : _ f_switch) ~(mk_app : _ f_app)
    ~(mk_dev : _ f_dev_full) t =
  let tbl = Tbl.create 50 in
  let rec aux : type a. a t -> r =
   fun impl ->
    if Tbl.mem tbl @@ abstract impl then Tbl.find tbl (abstract impl)
    else
      let acc =
        match impl with
        | Dev { dev; args; deps } ->
            let deps =
              List.fold_right (fun (Abstract x) l -> aux x :: l) deps []
            in
            let args = aux_tl args in
            mk_dev.f ~args ~deps dev
        | App { f; args } ->
            let f = aux f in
            let args = aux_tl args in
            mk_app ~f ~args
        | If { cond; branches; default } ->
            let branches = List.map (fun (p, t) -> (p, aux t)) branches in
            let default = aux default in
            mk_switch.if_ ~cond ~branches ~default
      in
      Tbl.add tbl (abstract impl) acc;
      acc
  and aux_tl : type a v. (a, v) tl -> r list = function
    | Nil -> []
    | Cons (h, t) -> aux h :: aux_tl t
  in
  aux t

type label = If : _ Key.value -> label | Dev : _ Device.t -> label | App

let collect : type ty.
    (module Misc.Monoid with type t = ty) -> (label -> ty) -> abstract -> ty =
 fun (module M) op (Abstract t) ->
  let r = ref M.empty in
  let add x = r := M.union (op x) !r in
  let mk_switch = { if_ = (fun ~cond ~branches:_ ~default:_ -> add @@ If cond) }
  and mk_app ~f:_ ~args:_ = add App
  and mk_dev = { f = (fun ~args:_ ~deps:_ dev -> add @@ Dev dev) } in
  let () = map ~mk_switch ~mk_app ~mk_dev t in
  !r

(* {2 Dot output} *)
module Dot = struct
  type edge_label =
    | Functor
    | Argument
    | Dependency
    | Branch of { default : bool }

  let as_dot_graph (Abstract t) =
    let r = ref 0 in
    let new_id () =
      incr r;
      !r
    in
    let vertices = ref [] in
    let edges = ref [] in
    let add r x = r := x :: !r in
    let mk_switch =
      {
        if_ =
          (fun ~cond ~branches ~default ->
            let id = new_id () in
            add vertices (id, If cond);
            List.iter
              (fun (_, id') -> add edges (id, id', Branch { default = false }))
              branches;
            add edges (id, default, Branch { default = true });
            id);
      }
    and mk_app ~f ~args =
      let id = new_id () in
      add vertices (id, App);
      add edges (id, f, Functor);
      List.iter (fun id' -> add edges (id, id', Argument)) args;
      id
    and mk_dev =
      {
        f =
          (fun ~args ~deps dev ->
            let id = new_id () in
            add vertices (id, Dev dev);
            List.iter (fun id' -> add edges (id, id', Argument)) args;
            List.iter (fun id' -> add edges (id, id', Dependency)) deps;
            id);
      }
    in
    let _ = map ~mk_switch ~mk_app ~mk_dev t in
    (List.rev !vertices, List.rev !edges)

  let pp_vertice ppf (id, label) =
    let attrs =
      match label with
      | App -> [ ("label", "$"); ("shape", "diamond") ]
      | If cond -> [ ("label", Fmt.str "If\n%a" Key.pp_deps cond) ]
      | Dev dev ->
          let name = Fmt.str "%s__%i" (Device.nice_name dev) id in
          let label =
            Fmt.str "%s\n%s\n%a" name (Device.module_name dev)
              Fmt.(list ~sep:(any ", ") Key.pp)
              (Device.keys dev)
          in
          [ ("label", label); ("shape", "box") ]
    in
    let pp_attr ppf (field, v) = Fmt.pf ppf "%s=%S" field v in
    Fmt.pf ppf "%d [%a];" id (Fmt.list ~sep:(Fmt.any ", ") pp_attr) attrs

  let pp_edges ppf (id, id', label) =
    let attrs =
      match label with
      | Functor -> [ ("style", "bold"); ("tailport", "sw") ]
      | Argument -> []
      | Dependency -> [ ("style", "dashed") ]
      | Branch { default } ->
          let l = [ ("style", "dotted"); ("headport", "n") ] in
          if default then ("style", "bold") :: l else l
    in
    let pp_attr ppf (field, v) = Fmt.pf ppf "%s=%S" field v in
    Fmt.pf ppf "%d -> %d [%a];" id id'
      (Fmt.list ~sep:(Fmt.any ", ") pp_attr)
      attrs

  let pp ppf t =
    let vertices, edges = as_dot_graph t in
    Fmt.pf ppf {|@[<v2>digraph G {@,ordering=out;@,%a@,@,%a@,}@]|}
      (Fmt.list ~sep:Fmt.cut pp_vertice)
      vertices
      (Fmt.list ~sep:Fmt.cut pp_edges)
      edges
end

let pp_dot = Dot.pp
