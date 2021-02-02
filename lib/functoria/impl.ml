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


(* (\* Helpers for If nodes. *\)
 * module If = struct
 *   type dir = Else | Then
 * 
 *   (\* type path = dir list * dir
 *    * 
 *    * let append (l, z) (l', z') = (l @ (z :: l'), z') *\)
 * 
 *   let singleton z = ([], z)
 * 
 *   let dir b = if b then singleton Then else singleton Else
 * 
 *   (\* let reduce k ~path ~add : path Key.value =
 *    *   let fuse v l = if v = path then append path l else path in
 *    *   Key.(pure fuse $ k $ add) *\)
 * end *)

type 'a t =
  | If : {
      cond : 't Key.value ;
      branches : ('t * 'a t) list ;
      default : 'a t ;
    } -> 'a t
  | Dev : {
      dev : 'a device;
      args : ('a, 'v) tl ;
      deps : abstract list ;
    } -> ' v t
  | App : {
      f : 'a t ;
      args : ('a, 'v) tl ;
    } -> 'v t

and abstract = Abstract : _ t -> abstract

and ('a, 'b) tl =
  | Nil : ('a, 'a) tl
  | Cons : 'a t * ('b, 'c) tl -> ('a -> 'b, 'c) tl

and 'a device = ('a, abstract) Device.t

(** Constructors *)

let abstract t = Abstract t

(* Devices *)

let mk_dev ~args ~deps dev =
  Dev {dev; args; deps}
let of_device dev = mk_dev ~args:Nil ~deps:(Device.extra_deps dev) dev

let v ?packages ?packages_v ?keys ?extra_deps ?connect ?configure ?files ?build
    ?clean module_name module_type =
  of_device
  @@ Device.v ?packages ?packages_v ?keys ?extra_deps ?connect ?configure ?files
       ?build ?clean module_name module_type

let main ?packages ?packages_v ?keys ?extra_deps module_name ty =
  let connect _ = Device.start in
  v ?packages ?packages_v ?keys ?extra_deps ~connect module_name ty

(* If *)

let mk_switch ~cond ~branches ~default =
  If {cond; branches; default}

let if_ cond then_ else_ =
  mk_switch ~cond:cond
    ~branches:[true, then_; false, else_]
    ~default:then_

let match_ cond ~default branches =
  mk_switch ~cond ~branches ~default

(* App *)

let rec concat_tl : type a b c. (a,b) tl -> (b,c) tl -> (a,c) tl =
  fun t1 t2 -> match t1 with
    | Nil -> t2
    | Cons (h, t) -> Cons (h, concat_tl t t2)

let rec mk_app : type a v. f:(a t) -> args:(a,v) tl -> v t =
  fun ~f ~args:args1 -> match f with
    | Dev {dev; args = args2; deps} ->
      mk_dev ~args:(concat_tl args2 args1) ~deps dev
    | App {f; args = args2} ->
      mk_app ~f ~args:(concat_tl args2 args1)
    | _ ->
      App {f ; args = args1 }

let ( $ ) f x = mk_app ~f ~args:(Cons (x, Nil))

(** Utilities *)

let rec pp : type a. a t Fmt.t =
  fun ppf -> function
    | Dev { dev; args; deps = _ } ->
      Fmt.pf ppf "@[<v>@[Dev %a@]@,@[<v2>args=[%a]@]@]" (Device.pp pp_abstract) dev pp_tl args
    | App { f; args } ->
      Fmt.pf ppf "App %a(%a)" pp f pp_tl args
    | If { cond = _; branches ; default } ->
      Fmt.pf ppf "Switch (_,%a,%a)"
        (Fmt.list pp) (List.map snd branches) pp default

and pp_tl : type a b. (a, b) tl Fmt.t =
  fun ppf -> function
    | Nil -> ()
    | Cons (h, t) -> Fmt.pf ppf "%a,@ %a" pp h pp_tl t

and pp_abstract ppf (Abstract i) = pp ppf i

let rec hash : type a. a t -> int = function
  | Dev { dev; args; deps } ->
    Hashtbl.hash
      (`Dev, Device.hash dev, hash_tl args, List.map hash_abstract deps)
  | App { f; args } ->
    Hashtbl.hash
      (`App, hash f, hash_tl args)
  | If {cond; branches; default} ->
    Hashtbl.hash
      (`If, cond, List.map (fun (p,t) -> Hashtbl.hash (p, hash t)) branches, hash default)
and hash_abstract (Abstract x) = hash x
and hash_tl : type a v. (a,v) tl -> int = fun x -> match x with
  | Nil -> Hashtbl.hash `Nil
  | Cons (h, t) ->
    Hashtbl.hash (`Cons, hash h, hash_tl t)

type ex = Ex : 'a -> ex
let rec equal : type t1 t2. t1 t -> t2 t -> bool =
  fun x y ->
  match x, y with
  | Dev c, Dev c' ->
    Device.equal c.dev c'.dev &&
    equal_tl c.args c'.args &&
    List.for_all2 equal_abstract c.deps c'.deps
  | App a, App b ->
    equal a.f b.f && equal_tl a.args b.args
  | If x1, If x2 ->
    (* Key.value is a functional value (it contains a closure for eval).
       There is no prettier way than physical equality. *)
    Obj.repr x1.cond == Obj.repr x2.cond &&
    List.for_all2
      (fun (p1,t1) (p2,t2) -> Ex p1 = Ex p2 && equal t1 t2)
      x1.branches x2.branches &&
    equal x1.default x2.default
  | _ -> false
and equal_abstract (Abstract x) (Abstract y) = equal x y
and equal_tl : type t1 t2 v1 v2. (t1,v1) tl -> (t2,v2) tl -> bool =
  fun x y ->
  match x, y with
  | Nil, Nil -> true
  | Cons (h1, t1), Cons (h2, t2) ->
    equal h1 h2 && equal_tl t1 t2
  | _ -> false

module Tbl = Hashtbl.Make (struct
  type t = abstract

  let hash = hash_abstract

  let equal = equal_abstract
end)

(* Safe, but annoying to code safely, so we cheat *)
module HC : sig
  type tbl
  val create : unit -> tbl
  val add : tbl -> 'a t -> 'a t -> unit
  val get : tbl -> 'a t -> 'a t option
end = struct
  type tbl = abstract Tbl.t
  let create () = Tbl.create 50
  let add tbl a b = Tbl.add tbl (abstract a) (abstract b)
  let get (type a) tbl (a : a t) =
    if Tbl.mem tbl @@ abstract a then
      let Abstract b = Tbl.find tbl (abstract a) in
      Some (Obj.magic b : a t)
    else
      None
end

let simplify ~partial ~context (Abstract t) =
  let tbl = HC.create () in
  let rec aux : type a. a t -> a t = fun impl ->
    match HC.get tbl impl with
    | Some impl' -> impl'
    | None ->
      let acc =
        match impl with
        | If { cond; branches ; default } ->
          if not partial || Key.mem context cond then
            let path = Key.eval context cond in
            let t =
              try List.assoc path branches
              with Not_found -> default
            in
            aux t
          else
            let branches = List.map (fun (p,t) -> (p, aux t)) branches in
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
      HC.add tbl impl acc;
      acc
  and aux_abstract (Abstract a) = Abstract (aux a)
  and aux_tl : type a v. (a, v) tl -> (a, v) tl = function
    | Nil -> Nil
    | Cons (h, t) -> Cons (aux h, aux_tl t)
  in
  Abstract (aux t)


let eval ~context (Abstract t) =
  let new_id = let r = ref 0 in fun () -> incr r; !r in
  let tbl = Tbl.create 50 in
  let rec aux : type a. a t -> Device_graph.t = fun impl ->
    if Tbl.mem tbl @@ abstract impl then Tbl.find tbl (abstract impl)
    else
      let acc =
        match impl with
        | Dev { dev; args; deps } ->
          let args = aux_tl args in
          let deps = List.map aux_abstract deps in
          Device_graph.D { dev ; args ; deps ; id = new_id ()} 
        | App { f; args = extra_args } ->
          let D { dev; args; deps; id = _ } = aux f in
          let extra_args = aux_tl extra_args in
          D { dev; args = args @ extra_args; deps; id = new_id ()}
        | If { cond; branches; default} ->
          let path = Key.eval context cond in
            let t =
              try List.assoc path branches
              with Not_found -> default
            in
          aux t
      in
      Tbl.add tbl (abstract impl) acc;
      acc
  and aux_abstract (Abstract a) = aux a
  and aux_tl : type a v. (a, v) tl -> _ = function
    | Nil -> []
    | Cons (h, t) -> let a = aux h in a :: aux_tl t
  in
  aux t

type 'b f_dev =
  { f : 'a. ('a, abstract) Device.t -> 'b }

let with_left_most_device ctx t (f : _ f_dev) =
  let rec aux : type a. a t -> _ = function
    | Dev d -> f.f d.dev
    | App a -> aux a.f
    | If { cond; branches ; default } ->
      let path = Key.eval ctx cond in
      let t =
        try List.assoc path branches
        with Not_found -> default
      in
      aux t
  in
  aux t

type 'b f_dev_full =
  { f : 'a 'v. args:'b list -> deps:'b list -> 'a device -> 'b }

type 'a f_switch =
  { if_ : 'r. cond:'r Key.value -> branches:('r *'a) list -> default:'a -> 'a }

type 'a f_app = f:'a -> args:'a list -> 'a

let map (type r)
    ~(mk_switch : _ f_switch) ~(mk_app : _ f_app) ~(mk_dev : _ f_dev_full) t
  =
  let tbl = Tbl.create 50 in
  let rec aux : type a. a t -> r =
    fun impl ->
      if Tbl.mem tbl @@ abstract impl then Tbl.find tbl (abstract impl)
      else
        let acc =
          match impl with
          | Dev { dev; args; deps } ->
            let deps =
              List.fold_right
                (fun (Abstract x) l -> aux x :: l)
                deps []
            in
            let args = aux_tl args in
            mk_dev.f ~args ~deps dev
          | App { f; args } ->
            let f = aux f in
            let args = aux_tl args in
            mk_app ~f ~args
          | If { cond; branches; default } ->
            let branches = List.map (fun (p,t) -> (p, aux t)) branches in
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

let collect
  : type ty.
    (module Misc.Monoid with type t = ty) -> (label -> ty) -> abstract -> ty
  = fun (module M) op (Abstract t) ->
    let r = ref M.empty in
    let add x = r := M.union (op x) !r in
    let mk_switch = {if_= fun ~cond ~branches:_ ~default:_ -> add @@ If cond }
    and mk_app ~f:_ ~args:_ = add App
    and mk_dev = { f = fun ~args:_ ~deps:_ dev -> add @@ Dev dev }
    in
    let () = map ~mk_switch ~mk_app ~mk_dev t in
    !r


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
