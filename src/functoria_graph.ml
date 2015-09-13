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

(** {1 Graph engine} *)

(** This module is not optimized for speed, it's optimized for correctness
    and readability. If you need to make it faster
    - Good luck.
    - Please update the invariant section.
*)

open Graph
open Functoria_misc
module Dsl = Functoria_dsl
module Key = Functoria_key

(** {2 Utility} *)

let fold_lefti f l z =
  fst @@ List.fold_left (fun (s,i) x -> f i x s, i+1) (z,0) l

(** Check if [l] is an increasing sequence from [O] to [len-1]. *)
let is_sequence l =
  snd @@
  List.fold_left
    (fun (i,b) (j,_) -> i+1, b && (i = j))
    (0,true)
    l

(** {2 Graph} *)

type subconf = <
  name: string ;
  module_name: string ;
  keys: Key.t list ;
  packages: string list Key.value ;
  libraries: string list Key.value ;
  connect : Dsl.Info.t -> string -> string list -> string ;
  configure: Dsl.Info.t -> (unit, string) Rresult.result ;
  clean: Dsl.Info.t -> (unit, string) Rresult.result ;
>

type label =
  | If of bool Key.value
  | Impl of subconf
  | App

type edge_label =
  | Parameter of int
  | Dependency of int
  | Condition of [`Else | `Then]



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

(** The invariants of graphs manipulated here are:
    - [If] vertices have exactly 2 children,
      one [Condition `Else] and one [Condition `Then]
    - [Impl] vertices have [n] [Parameter] children and [m] [Dependency] children.
      [Parameter] (resp. [Dependency]) children are labeled
      from [0] to [n-1] (resp. [m-1]).
      They do not have [Condition] children.
    - [App] vertices have [n] [Parameter] children, with [n >= 2].
      They are labeled similarly to [Impl] vertex's children.
      They have neither [Condition] nor [dependency] children.
    - There are no cycles.
    - There is only one root (vertex with a degree 1). There are no orphans.
*)

(** {3 Graph utilities} *)

let add_edge e1 label e2 graph =
  G.add_edge_e graph @@ G.E.create e1 label e2

let for_all_vertex f g =
  G.fold_vertex (fun v b -> b && f v) g true

(** Remove a vertex and all its orphan successors, recursively. *)
let rec remove_rec g v =
  let children = G.succ g v in
  let g = G.remove_vertex g v in
  List.fold_right
    (fun c g -> remove_rec_if_orphan g c)
    children
    g

and remove_rec_if_orphan g c =
  if G.in_degree g c = 0
  then remove_rec g c
  else g

(** [add_pred_with_subst g preds v] add the edges [pred] to [g]
    with the destination replaced by [v]. *)
let add_pred_with_subst g preds v =
  List.fold_left
    (fun g e -> G.add_edge_e g @@ G.E.(create (src e) (label e) v))
    g
    preds

(** {2 Graph construction} *)

let add_impl graph ~impl ~args ~deps =
  let v = G.V.create (Impl impl) in
  v,
  graph
  |> fold_lefti (fun i -> add_edge v (Parameter i)) args
  |> fold_lefti (fun i -> add_edge v (Dependency i)) deps

let add_if graph ~cond ~else_ ~then_ =
  let v = G.V.create (If cond) in
  v,
  graph
  |> add_edge v (Condition `Else) else_
  |> add_edge v (Condition `Then) then_

let add_app graph ~f ~x =
  let v = G.V.create App in
  v,
  graph
  |> add_edge v (Parameter 0) f
  |> add_edge v (Parameter 1) x

let create impl =
  let module H = Dsl.ImplTbl in
  let tbl = H.create 50 in
  let rec aux
    : type t . G.t -> t Dsl.impl -> G.vertex * G.t
    = fun g impl ->
      if H.mem tbl @@ Dsl.hide impl
      then H.find tbl (Dsl.hide impl), g
      else
        let v, g = match impl with
          | Dsl.Impl c ->
            let deps, g =
              List.fold_right
                (fun (Dsl.Any x) (l,g) -> let v, g = aux g x in v::l, g)
                c#dependencies ([], g)
            in
            add_impl g ~impl:(c :> subconf) ~args:[] ~deps
          | Dsl.If (cond, then_, else_) ->
            let then_, g = aux g then_ in
            let else_, g = aux g else_ in
            add_if g ~cond ~then_ ~else_
          | Dsl.App {f; x} ->
            let f, g = aux g f in
            let x, g = aux g x in
            add_app g ~f ~x
        in
        H.add tbl (Dsl.hide impl) v ;
        v, g
  in
  snd @@ aux G.empty impl

let is_impl v = match G.V.label v with
  | Impl _ -> true
  | _ -> false

(** {2 Graph destruction/extraction} *)

let collect
  : type ty. (module Monoid with type t = ty) ->
    (label -> ty) -> G.t -> ty
  = fun (module M) f g ->
    G.fold_vertex (fun v s -> M.union s @@ f (G.V.label v)) g M.empty

let get_children g v =
  let split l =
    List.fold_right
      (fun e (args, deps, conds) -> match G.E.label e with
         | Parameter i -> (i, G.E.dst e)::args, deps, conds
         | Dependency i -> args, (i, G.E.dst e)::deps, conds
         | Condition side -> args, deps, (side, G.E.dst e)::conds)
      l
      ([],[],[])
  in
  let args, deps, cond = split @@ G.succ_e g v in
  let args = List.sort (fun (i,_) (j,_) -> compare i j) args in
  let deps = List.sort (fun (i,_) (j,_) -> compare i j) deps in
  let cond = match cond with
    | [`Else, else_ ; `Then, then_]
    | [`Then, then_; `Else, else_] -> Some (then_, else_)
    | [] -> None
    | _ -> assert false
  in
  assert (is_sequence args) ;
  assert (is_sequence deps) ;
  `Args (List.map snd args), `Deps (List.map snd deps), cond

let explode g v = match G.V.label v, get_children g v with
  | Impl i, (args, deps, None) -> `Impl (i, args, deps)
  | If cond, (`Args [], `Deps [], Some (then_, else_)) ->
    `If (cond, then_, else_)
  | App, (`Args (f::args), `Deps [], None) -> `App (f, args)
  | _ -> assert false

let fold f g z =
  if Dfs.has_cycle g then
    invalid_arg "Functoria_graph.iter: A graph should not have cycles." ;
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

(** {2 Graph manipulation} *)

(** Find a pattern in a graph. *)
exception Found
let find g predicate =
  let r = ref None in
  try
    G.iter_vertex
      (fun v -> match predicate g v with
         | Some _ as x -> r := x ; raise Found
         | None -> ())
      g ; None
  with Found -> !r

(** Find a pattern and apply the transformation, repeatedly. *)
(* This could probably be made more efficient, but it would be complicated. *)
let rec transform ~predicate ~apply g =
  match find g predicate with
  | Some v_if ->
    transform ~predicate ~apply @@ apply g v_if
  | None -> g

module RemovePartialApp = struct
  (** Remove [App] vertices.

      The goal here is to remove partial application of functor.
      If we find an [App] vertex with an implementation as first children,
      We fuse them and create one [Impl] vertex.
  *)

  let predicate g v = match explode g v with
    | `App (f,args) -> begin match explode g f with
        | `Impl (impl, `Args args', `Deps deps) ->
          Some (v, f, impl, args' @ args, deps)
        | _ -> None
      end
    | _ -> None

  let apply g (v_app, v_f, impl, args, deps) =
    let preds = G.pred_e g v_app in
    let g = G.remove_vertex g v_app in
    let v_impl', g = add_impl g ~impl ~args ~deps in
    let g = add_pred_with_subst g preds v_impl' in
    remove_rec_if_orphan g v_f

end

module EvalIf = struct
  (** Evaluate the [If] vertices and remove them. *)

  let predicate ~partial _ v = match G.V.label v with
    | If cond when not partial || Key.peek cond <> None -> Some v
    | _ -> None

  let apply ~partial g v_if =
    let cond, then_, else_ =
      match explode g v_if with
      | `If x -> x | _ -> assert false
    in
    let preds = G.pred_e g v_if in
    match Key.peek cond with
    | None when partial -> g
    | _ ->
      let v_new, v_rem =
        if Key.eval cond then then_, else_ else else_,then_
      in
      let g = G.remove_vertex g v_if in
      let g = remove_rec g v_rem in
      add_pred_with_subst g preds v_new

end

let normalize = RemovePartialApp.(transform ~predicate ~apply)

let eval ?(partial=false) g =
  normalize @@
  EvalIf.(transform
      ~predicate:(predicate ~partial)
      ~apply:(apply ~partial)
      g)

let is_fully_reduced g =
  for_all_vertex (fun v -> is_impl v) g


(** {2 Dot output} *)

module Dot = Graphviz.Dot(struct
    include G

    (* If you change the styling, please update the documentation of the
       describe command in {!Functorial_tool}. *)

    let graph_attributes _g = [ `OrderingOut ]
    let default_vertex_attributes _g = []

    let vertex_name v = string_of_int @@ V.hash v

    let vertex_attributes v = match V.label v with
      | App -> [ `Label "$" ; `Shape `Diamond ]
      | If cond ->
        [ `Label (Fmt.strf "If\n%a" Key.pp_deps cond) ]
      | Impl f ->
        let label =
          Fmt.strf
            "%s<br />%s"
            f#name f#module_name
        in
        [ `HtmlLabel label ;
          `Shape `Box ;
        ]

    let get_subgraph _g = None

    let default_edge_attributes _g = []
    let edge_attributes e = match E.label e with
      (* The functor part of an App is in bold. *)
      | Parameter 0 when V.label @@ E.src e = App ->
        [ `Style `Bold ]
      | Parameter _ -> [ ]
      | Dependency _ -> [ `Style `Dashed ]

      | Condition side ->
        let side = (side = `Then) in
        let color = if side then 0x008325 else 0xB31E18 in
        let cond = match V.label @@ E.src e with
          | If cond -> cond | _ -> assert false
        in
        let tailport = if side then `SW else `SE in
        let l = [ `Color color ; `Tailport tailport ; `Headport `N ] in
        if Key.eval cond = side then `Style `Bold :: l else l

  end )

let pp_dot = Dot.fprint_graph

let pp = Fmt.nop
