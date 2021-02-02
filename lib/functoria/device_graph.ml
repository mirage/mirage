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

(* {1 Graph engine} *)

(* This module is not optimized for speed, it's optimized for correctness
   and readability. If you need to make it faster:
     - Good luck.
     - Please update the invariant section.
*)

open Astring
open DSL

(* {2 Graph} *)

(* Helpers for If nodes. *)
module If = struct
  type dir = Else | Then

  type path = dir list * dir

  let append (l, z) (l', z') = (l @ (z :: l'), z')

  let singleton z = ([], z)

  let dir b = if b then singleton Then else singleton Else

  let fuse path v l = if v = path then append path l else path

  let reduce f ~path ~add : path Key.value = Key.(pure (fuse path) $ f $ add)
end

module M = struct

  type t =
    | If : {
        cond : If.path Key.value ;
        branches : (If.path * t) list ;
      } -> t
    | Dev : {
        dev : 'a device;
        args : t list ;
        deps : t list ;
      } -> t
    | App : {
        f : t ;
        args : t list ;
      } -> t

  let rec hash : t -> int = function
    | Dev { dev; args; deps } ->
      Hashtbl.hash (Device.hash dev, List.map hash args, List.map hash deps)
    | App { f; args } -> Hashtbl.hash (hash f, List.map hash args)
    | If {cond; branches} ->
      Hashtbl.hash
        (cond, List.map (fun (p,t) -> Hashtbl.hash (p, hash t)) branches)

  let rec equal : t -> t -> bool =
    fun x y ->
    match x, y with
    | Dev c, Dev c' ->
      Device.equal c.dev c'.dev &&
      List.for_all2 equal c.args c'.args &&
      List.for_all2 equal c.deps c'.deps
    | App a, App b -> equal a.f b.f && List.for_all2 equal a.args b.args
    | If x1, If x2 ->
      (* Key.value is a functional value (it contains a closure for eval).
         There is no prettier way than physical equality. *)
      x1.cond == x2.cond &&
      List.for_all2 (fun (p1,t1) (p2,t2) -> p1 = p2 && equal t1 t2)
        x1.branches x2.branches
    | _ -> false

end
include M

type label = If of If.path Key.value | Dev : 'a device -> label | App

let mk_dev (type a) ~args ~deps (dev : a device) : t =
  Dev {dev; args; deps}

let mk_switch ~cond branches : t =
  If {cond; branches}

let mk_if ~cond ~else_ ~then_ : t =
  mk_switch ~cond:(Key.map If.dir cond)
    [ If.(singleton Else), else_; If.(singleton Then), then_ ]

let mk_app ~f ~args : t =
  App {f ; args}

let create impl : t =
  let dev = { Impl.f = (fun d ~deps -> mk_dev ~args:[] ~deps d) } in
  let if_ ~cond ~then_ ~else_ = mk_if ~cond ~then_ ~else_ in
  let app ~f ~x = mk_app ~f ~args:[ x ] in
  Impl.map ~dev ~if_ ~app impl

module Tbl = Hashtbl.Make (M)


type 'b f_dev =
  { f : 'a. id:int -> args:'b list -> deps:'b list -> 'a device -> 'b }
let mk_dev' = { f = fun ~id:_ -> mk_dev }

let map (type r) ~mk_switch ~mk_app ~mk_dev t =
  let tbl = Tbl.create 50 in
  let rec aux : t -> r =
   fun impl ->
    if Tbl.mem tbl impl then Tbl.find tbl impl
    else
      let acc =
        match impl with
        | Dev { dev; args; deps } ->
            let deps = List.map aux deps in
            let args = List.map aux args in
            mk_dev.f dev ~deps ~args ~id:(M.hash impl)
        | App { f; args } ->
          let args = List.map aux args in
          let f = aux f in
          mk_app ~f ~args
        | If {cond ; branches } ->
          let branches = List.map (fun (p,t) -> (p, aux t)) branches in
          mk_switch ~cond branches
      in
      Tbl.add tbl impl acc;
      acc
  in
  aux t


let set_equal l1 l2 = Key.Set.equal (Key.deps l1) (Key.deps l2)
let normalize t =
  let rec apply_app ~(f : t) ~args:args1 = 
    match f with
    | Dev {dev; args = args2; deps} ->
      mk_dev ~args:(args2 @ args1) ~deps dev
    | App {f; args = args2} ->
      apply_app ~f ~args:(args2 @ args1)
    | _ ->
      mk_app ~f ~args:args1
  in
  let reduce_if ~cond branches =
    let f (new_cond, new_l) (path, (t : t)) =
      match t with
      | If c when set_equal cond c.cond ->
        let new_cond = If.reduce cond ~path ~add:c.cond in
        let new_branches =
          List.map (fun (p, v) -> (If.append path p, v)) c.branches @ new_l
        in
        new_cond, new_branches
      | _ ->
        new_cond, (path, t) :: new_l
    in
    let cond, branches = List.fold_left f (cond, []) branches in
    mk_switch ~cond branches
  in
  map ~mk_app:apply_app ~mk_switch:reduce_if ~mk_dev:mk_dev' t

let eval_if ~partial ~context t =
  let eval_if ~cond branches =
    if not partial || Key.mem context cond then
      let path = Key.eval context cond in
      let t = List.assoc path branches in
      t
    else
      mk_switch ~cond branches
  in
  map ~mk_app ~mk_switch:eval_if ~mk_dev:mk_dev' t

let eval ?(partial = false) ~context t =
  normalize @@ eval_if ~partial ~context t

let rec is_fully_reduced (t : t) = match t with
  | Dev { args; deps; _ } ->
    List.for_all is_fully_reduced args &&
    List.for_all is_fully_reduced deps
  | If _ -> false | App _ -> false

let nice_name d =
  Device.module_name d
  |> String.cuts ~sep:"."
  |> String.concat ~sep:"_"
  |> String.Ascii.lowercase
  |> Misc.Name.ocamlify

(* {2 Destruction/extraction} *)

type a_device = D : 'a device -> a_device

let explode : t -> _ = function
  | Dev {dev; args; deps} -> `Dev (D dev, `Args args, `Deps deps)
  | If {cond; branches} -> `If (cond, branches)
  | App {f; args} -> `App (f, args)

let collect
  : type ty. (module Misc.Monoid with type t = ty) -> (label -> ty) -> t -> ty
  = fun (module M) op t ->
    let (+) = M.union in
    let union_l = List.fold_left M.union M.empty in
    let mk_switch ~cond branches = op (If cond) + union_l (List.map snd branches)
    and mk_app ~f ~args = op App + f + union_l args
    and mk_dev =
      { f = (fun ~id:_ ~args ~deps dev ->
            op (Dev dev) + union_l args + union_l deps) }
    in
    map ~mk_switch ~mk_app ~mk_dev t

let devices t =
  let r = ref [] in
  let mk_app ~f:_ ~args:_ = ()
  and mk_dev = { f = fun ~id:_ ~args:_ ~deps:_ dev -> r := D dev :: !r }
  and mk_switch ~cond:_ _ = ()
  in
  map ~mk_switch ~mk_app ~mk_dev t;
  !r

type dtree = {
  dev : a_device ;
  args : dtree list ;
  deps : dtree list ;
  id : int ;
}

exception Not_reduced

let dtree t =
  let mk_app ~f:_ ~args:_ = raise Not_reduced
  and mk_switch ~cond:_ _ = raise Not_reduced
  and mk_dev = { f = fun ~id ~args ~deps dev ->
      { dev = D dev; args; deps; id}
    }
  in
  try Some (map ~mk_switch ~mk_app ~mk_dev t)
  with Not_reduced -> None

module IdTbl = Hashtbl.Make(struct
    type t = dtree
    let hash t = t.id
    let equal t1 t2 = Int.equal t1.id t2.id
  end)

(* We iter in *reversed* topological order. *)
let fold_dtree f t z =
  let tbl = IdTbl.create 50 in
  let state = ref z in
  let rec aux v =
    if IdTbl.mem tbl v then ()
    else
      let { args; deps; _} = v in
      IdTbl.add tbl v ();
      List.iter aux @@ List.rev deps;
      List.iter aux @@ List.rev args;
      state := f v !state
  in
  aux t;
  !state

let impl_name { dev = D dev; args = _; deps = _ ; id } =
  match Type.is_functor (Device.module_type dev) with
  | false -> Device.module_name dev
  | true ->
    let prefix = String.Ascii.capitalize (nice_name dev) in
    Fmt.strf "%s__%d" prefix id

let var_name { dev = D dev; args = _; deps = _ ; id} =
  let prefix = nice_name dev in
  Fmt.strf "%s__%i" prefix id



(* {2 Dot output} *)

(* module Dot = Graphviz.Dot (struct
 *   include G
 * 
 *   (\* If you change the styling, please update the documentation of the
 *        describe command in {!Functorial_tool}. *\)
 * 
 *   let graph_attributes _g = [ `OrderingOut ]
 * 
 *   let default_vertex_attributes _g = []
 * 
 *   let vertex_name v = string_of_int @@ V.hash v
 * 
 *   let vertex_attributes v =
 *     match V.label v with
 *     | App -> [ `Label "$"; `Shape `Diamond ]
 *     | If cond -> [ `Label (Fmt.strf "If\n%a" Key.pp_deps cond) ]
 *     | Dev f ->
 *         let label =
 *           Fmt.strf "%s\n%s\n%a" (var_name v) (Device.module_name f)
 *             Fmt.(list ~sep:(unit ", ") Key.pp)
 *             (Device.keys f)
 *         in
 *         [ `Label label; `Shape `Box ]
 * 
 *   let get_subgraph _g = None
 * 
 *   let default_edge_attributes _g = []
 * 
 *   let edge_attributes e =
 *     match E.label e with
 *     | Functor -> [ `Style `Bold; `Tailport `SW ]
 *     | Parameter _ -> []
 *     | Dependency _ -> [ `Style `Dashed ]
 *     | Condition path ->
 *         let cond =
 *           match V.label @@ E.src e with
 *           | If cond -> cond
 *           | App | Dev _ -> assert false
 *         in
 *         let l = [ `Style `Dotted; `Headport `N ] in
 *         if Key.default cond = path then `Style `Bold :: l else l
 * end) *)

let pp_dot = Fmt.nop

let pp = Fmt.nop
