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

(* {1 Graph engine} *)

(* This module is not optimized for speed, it's optimized for correctness
   and readability. If you need to make it faster:
     - Good luck.
     - Please update the invariant section.
*)

open Graph
open Functoria_misc
open Functoria

module Key = Functoria_key

(* {2 Utility} *)

let fold_lefti f l z =
  fst @@ List.fold_left (fun (s,i) x -> f i x s, i+1) (z,0) l

(* Check if [l] is an increasing sequence from [O] to [len-1]. *)
let is_sequence l =
  snd @@
  List.fold_left
    (fun (i,b) (j,_) -> i+1, b && (i = j))
    (0,true)
    l

(* {2 Graph} *)

type subconf = <
  name: string;
  module_name: string;
  keys: Key.t list;
  packages: package list Key.value;
  connect: Info.t -> string -> string list -> string;
  build: Info.t -> (unit, [ `Msg of string ]) Rresult.result;
  configure: Info.t -> (unit, [ `Msg of string ]) Rresult.result;
  clean: Info.t -> (unit, [ `Msg of string ]) Rresult.result;
>

(* Helpers for If nodes. *)
module If = struct
  type dir = Else | Then
  type path = dir list * dir
  let append (l,z) (l',z') = (l@z::l', z')
  let singleton z = ([],z)
  let dir b = if b then singleton Then else singleton Else
  let fuse path v l = if v = path then append path l else path
  let reduce f ~path ~add : path Key.value = Key.(pure (fuse path) $ f $ add)
end

type label =
  | If of If.path Key.value
  | Impl of subconf
  | App

type edge_label =
  | Parameter of int
  | Dependency of int
  | Condition of If.path
  | Functor



module V_ = struct
  type t = label
end

module E_ = struct
  type t = edge_label
  let default = Parameter 0
  let compare = compare
end

module G = Persistent.Digraph.AbstractLabeled (V_) (E_)
module Tbl = Hashtbl.Make(G.V)

type t = G.t
type vertex = G.V.t

module Dfs = Traverse.Dfs(G)
module Topo = Topological.Make(G)

(* The invariants of graphs manipulated here are:

    - [If] vertices have exactly [n] [Condition] children.

    - [Impl] vertices have [n] [Parameter] children and [m]
      [Dependency] children. [Parameter] (resp. [Dependency]) children
      are labeled from [0] to [n-1] (resp. [m-1]).  They do not have
      [Condition] nor [Functor] children.

    - [App] vertices have one [Functor] child and [n] [Parameter]
      children (with [n >= 1]) following the [Impl] convention. They
      have neither [Condition] nor [Dependency] children.

    - There are no cycles.

    - There is only one root (vertex with a degree 1). There are no orphans.

*)

(* {3 Graph utilities} *)

let hash = G.V.hash

let add_edge e1 label e2 graph =
  G.add_edge_e graph @@ G.E.create e1 label e2

let for_all_vertex f g =
  G.fold_vertex (fun v b -> b && f v) g true

(* Remove a vertex and all its orphan successors, recursively. *)
let rec remove_rec g v =
  let children = G.succ g v in
  let g = G.remove_vertex g v in
  List.fold_right
    (fun c g -> remove_rec_if_orphan g c)
    children
    g

and remove_rec_if_orphan g c =
  if G.mem_vertex g c && G.in_degree g c = 0
  then remove_rec g c
  else g

(* [add_pred_with_subst g preds v] add the edges [pred] to [g]
   with the destination replaced by [v]. *)
let add_pred_with_subst g preds v =
  List.fold_left
    (fun g e -> G.add_edge_e g @@ G.E.(create (src e) (label e) v))
    g
    preds

(* {2 Graph construction} *)

let add_impl graph ~impl ~args ~deps =
  let v = G.V.create (Impl impl) in
  v,
  G.add_vertex graph v
  |> fold_lefti (fun i -> add_edge v (Parameter i)) args
  |> fold_lefti (fun i -> add_edge v (Dependency i)) deps

let add_switch graph ~cond l =
  let v = G.V.create (If cond) in
  v,
  List.fold_right (fun (p,v') -> add_edge v (Condition p) v') l @@
  G.add_vertex graph v

let add_if graph ~cond ~else_ ~then_ =
  add_switch graph ~cond:(Key.map If.dir cond)
    [ If.(singleton Else), else_; If.(singleton Then), then_ ]

let add_app graph ~f ~args =
  let v = G.V.create App in
  v,
  G.add_vertex graph v
  |> add_edge v Functor f
  |> fold_lefti (fun i -> add_edge v (Parameter i)) args

let create impl =
  let module H = ImplTbl in
  let tbl = H.create 50 in
  let rec aux: type t . G.t -> t impl -> G.vertex * G.t
    = fun g impl ->
      if H.mem tbl @@ abstract impl
      then H.find tbl (abstract impl), g
      else
        let v, g = match explode impl with
          | `Impl c ->
            let deps, g =
              List.fold_right
                (fun (Abstract x) (l,g) -> let v, g = aux g x in v::l, g)
                c#deps ([], g)
            in
            add_impl g ~impl:(c :> subconf) ~args:[] ~deps
          | `If (cond, then_, else_) ->
            let then_, g = aux g then_ in
            let else_, g = aux g else_ in
            add_if g ~cond ~then_ ~else_
          | `App (Abstract f , Abstract x) ->
            let f, g = aux g f in
            let x, g = aux g x in
            add_app g ~f ~args:[x]
        in
        H.add tbl (abstract impl) v;
        v, g
  in
  snd @@ aux G.empty impl

let is_impl v = match G.V.label v with
  | Impl _ -> true
  | App | If _ -> false

(* {2 Graph destruction/extraction} *)

let collect
  : type ty. (module Monoid with type t = ty) ->
    (label -> ty) -> G.t -> ty
  = fun (module M) f g ->
    G.fold_vertex (fun v s -> M.union s @@ f (G.V.label v)) g M.empty

let get_children g v =
  let split l =
    List.fold_right
      (fun e (args, deps, conds, funct) ->
         let v = G.E.dst e in match G.E.label e with
         | Parameter i -> (i, v)::args, deps, conds, funct
         | Dependency i -> args, (i, v)::deps, conds, funct
         | Condition path -> args, deps, (path, v)::conds, funct
         | Functor -> args, deps, conds, v :: funct
      )
      l
      ([],[],[],[])
  in
  let args, deps, cond, funct = split @@ G.succ_e g v in
  let args = List.sort (fun (i,_) (j,_) -> compare i j) args in
  let deps = List.sort (fun (i,_) (j,_) -> compare i j) deps in
  let funct = match funct with
    | [] -> None | [ x ] -> Some x
    | _ -> assert false
  in
  assert (is_sequence args);
  assert (is_sequence deps);
  `Args (List.map snd args), `Deps (List.map snd deps), cond, funct

let explode g v =
  match G.V.label v, get_children g v with
  | Impl i , (args      , deps    , [], None  ) -> `Impl (i, args, deps)
  | If cond, (`Args []  , `Deps [], l , None  ) -> `If (cond, l)
  | App    , (`Args args, `Deps [], [], Some f) -> `App (f, args)
  | (Impl _ | If _ | App), _ -> assert false

let fold f g z =
  if Dfs.has_cycle g then
    invalid_arg "Functoria_graph.iter: A graph should not have cycles.";
  (* We iter in *reversed* topological order. *)
  let l = Topo.fold (fun x l -> x :: l) g [] in
  List.fold_left (fun z l -> f l z) z l

let find_all_v g p =
  G.fold_vertex
    (fun v l -> if p v then v :: l else l)
    g []

let find_all g p = find_all_v g (fun x -> p @@ G.V.label x)

let find_root g =
  let l = find_all_v g (fun v -> G.in_degree g v = 0) in
  match l with
  | [ x ] -> x
  | _ -> invalid_arg
           "Functoria_graph.find_root: A graph should have only one root."

(* {2 Graph manipulation} *)

(* Find a pattern in a graph. *)
exception Found
let find g predicate =
  let r = ref None in
  try
    G.iter_vertex
      (fun v -> match predicate g v with
         | Some _ as x -> r := x; raise Found
         | None -> ())
      g; None
  with Found -> !r

(* Find a pattern and apply the transformation, repeatedly. This could
   probably be made more efficient, but it would be complicated. *)
let rec transform ~predicate ~apply g =
  match find g predicate with
  | Some v_if ->
    transform ~predicate ~apply @@ apply g v_if
  | None -> g

module RemovePartialApp = struct
  (* Remove [App] vertices.

     The goal here is to remove partial application of functor.  If we
     find an [App] vertex with an implementation as first children, We
     fuse them and create one [Impl] vertex.

     If we find successive [App] vertices, we merge them.
  *)

  let predicate g v = match explode g v with
    | `App (v',args) -> begin match explode g v' with
        | `Impl (impl, `Args args', `Deps deps) ->
          let add g = add_impl g ~impl ~args:(args'@args) ~deps in
          Some (v, v', add)
        | `App (f, args') ->
          let add g = add_app g ~f ~args:(args' @ args) in
          Some (v, v', add)
        | _ -> None
      end
    | _ -> None

  let apply g (v_app, v_f, add) =
    let preds = G.pred_e g v_app in
    let g = G.remove_vertex g v_app in
    let v_impl', g = add g in
    let g = add_pred_with_subst g preds v_impl' in
    remove_rec_if_orphan g v_f

end

module MergeNode = struct
  (* Merge successive If nodes with the same set of dependencies.

     This is completely useless for evaluation but very helpful for
     graph visualization by humans.
  *)

  let set_equal l1 l2 =
    Key.Set.equal (Key.deps l1) (Key.deps l2)

  let predicate g v = match explode g v with
    | `If (cond, l) ->
      if List.exists (fun (_,v) ->
          match G.V.label v with
          | If cond' -> set_equal cond cond'
          | App
          | Impl _   -> false
        ) l
      then Some (v, cond, l)
      else None
    | _ -> None


  let apply g (v_if, cond, l) =
    let f (new_cond, new_l) (path, v) = match explode g v with
      | `If (cond', l') when set_equal cond cond' ->
        If.reduce cond ~path ~add:cond',
        List.map (fun (p,v) -> If.append path p, v) l' @ new_l
      | _ ->
        new_cond, (path,v) :: new_l
    in
    let new_cond, new_l = List.fold_left f (cond,[]) l in
    let preds = G.pred_e g v_if in
    let g = G.remove_vertex g v_if in
    let v_new, g = add_switch g ~cond:new_cond new_l in
    let g = add_pred_with_subst g preds v_new in
    List.fold_left remove_rec_if_orphan g @@ List.map snd l

end

module EvalIf = struct
  (* Evaluate the [If] vertices and remove them. *)

  let predicate ~partial ~context _ v = match G.V.label v with
    | If cond when not partial || Key.mem context cond -> Some v
    | If _ | App | Impl _ -> None

  let extract path l =
    let rec aux = function
      | [] -> invalid_arg "Path is not present."
      | (path',v) :: t when path = path' -> v, List.map snd t
      | (_    ,v) :: t -> let v_found, l = aux t in v_found, v::l
    in
    aux l

  let apply ~partial ~context g v_if =
    let path, l =
      match explode g v_if with
      | `If x -> x | _ -> assert false
    in
    let preds = G.pred_e g v_if in
    if partial && not @@ Key.mem context path then g
    else
      let v_new, v_others = extract (Key.eval context path) l in
      let g = G.remove_vertex g v_if in
      let g = List.fold_left remove_rec_if_orphan g v_others in
      add_pred_with_subst g preds v_new

end

let simplify = MergeNode.(transform ~predicate ~apply)

let normalize = RemovePartialApp.(transform ~predicate ~apply)

let eval ?(partial=false) ~context g =
  normalize @@
  EvalIf.(transform
            ~predicate:(predicate ~partial ~context)
            ~apply:(apply ~partial ~context)
            g)

let is_fully_reduced g =
  for_all_vertex (fun v -> is_impl v) g


(* {2 Dot output} *)

module Dot = Graphviz.Dot(struct
    include G

    (* If you change the styling, please update the documentation of the
       describe command in {!Functorial_tool}. *)

    let graph_attributes _g = [ `OrderingOut ]
    let default_vertex_attributes _g = []

    let vertex_name v = string_of_int @@ V.hash v

    let vertex_attributes v = match V.label v with
      | App -> [ `Label "$"; `Shape `Diamond ]
      | If cond ->
        [ `Label (Fmt.strf "If\n%a" Key.pp_deps cond) ]
      | Impl f ->
        let label =
          Fmt.strf
            "%s\n%s\n%a"
            f#name f#module_name
            Fmt.(list ~sep:(unit ", ") Key.pp)
            f#keys
        in
        [ `Label label; `Shape `Box; ]

    let get_subgraph _g = None

    let default_edge_attributes _g = []
    let edge_attributes e = match E.label e with
      | Functor -> [ `Style `Bold; `Tailport `SW]
      | Parameter _ -> [ ]
      | Dependency _ -> [ `Style `Dashed ]

      | Condition path ->
        let cond =
          match V.label @@ E.src e with
          | If cond -> cond | App | Impl _ -> assert false
        in
        let l = [ `Style `Dotted; `Headport `N ] in
        if Key.default cond = path then `Style `Bold :: l else l

  end )

let pp_dot = Dot.fprint_graph
let pp = Fmt.nop
