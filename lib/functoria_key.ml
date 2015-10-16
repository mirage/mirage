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

module Serialize = struct
  let string fmt s = Format.fprintf fmt "%S" s
  let option x = Fmt.(parens @@ Dump.option x)
  let list x = Fmt.Dump.list x
end

module Arg = struct

  type 'a serialize = Format.formatter -> 'a -> unit
  type 'a runtime_conv = string
  type 'a converter = 'a Cmdliner.Arg.converter * 'a serialize * 'a runtime_conv

  let converter (x, _, _) = x
  let serialize (_, x, _) = x
  let runtime_conv (_, _, x) = x

  let string =
    Cmdliner.Arg.string,
    (fun fmt -> Format.fprintf fmt "%S"),
    "Cmdliner.Arg.string"

  let bool =
    Cmdliner.Arg.bool,
    (fun fmt -> Format.fprintf fmt "%b"),
    "Cmdliner.Arg.bool"

  let int =
    Cmdliner.Arg.int,
    (fun fmt -> Format.fprintf fmt "%i"),
    "Cmdliner.Arg.int"

  let list d =
    Cmdliner.Arg.list (converter d),
    Serialize.list (serialize d),
    Fmt.strf "(Cmdliner.Arg.list %s)" (runtime_conv d)

  let some d =
    Cmdliner.Arg.some (converter d),
    Serialize.option (serialize d),
    Fmt.strf "(Cmdliner.Arg.some %s)" (runtime_conv d)

  type info = {
    doc  : string option;
    docs : string;
    docv : string option;
    names: string list;
    env  : string option;
  }

  let info ?(docs="UNIKERNEL PARAMETERS") ?docv ?doc ?env names =
    { doc; docs; docv; names; env }

  let cmdliner_of_info { docs; docv; doc; env; names } =
    let env = match env with
      | Some s -> Some (Cmdliner.Arg.env_var s)
      | None   -> None
    in
    Cmdliner.Arg.info ~docs ?docv ?doc ?env names

  let serialize_env fmt =
    Fmt.pf fmt "(Cmdliner.Arg.env_var %a)" Serialize.string

  let serialize_info fmt { docs; docv; doc; env; names } =
    Format.fprintf fmt
      "(Cmdliner.Arg.info@ ~docs:%a@ ?docv:%a@ ?doc:%a@ ?env:%a@ %a)"
      Serialize.string docs
      Serialize.(option string) docv
      Serialize.(option string) doc
      Serialize.(option serialize_env) env
      Serialize.(list string) names

  type 'a kind =
    | Opt : 'a converter -> 'a kind
    | Flag: bool kind

  type stage = [
    | `Configure
    | `Run
    | `Both
  ]

  let pp_conv c = snd (converter c)

  let pp_kind: type a . a kind -> a Fmt.t = function
    | Opt c -> pp_conv c
    | Flag  -> Fmt.bool

  type 'a t = {
    stage  : stage;
    default: 'a;
    info   : info;
    kind   : 'a kind;
  }

  let pp t = pp_kind t.kind
  let stage t = t.stage
  let default t = t.default

  let opt ?(stage=`Both) conv default info =
    { stage; info; default; kind = Opt conv }

  let flag ?(stage=`Both) info =
    { stage; info; default = false; kind = Flag }

  let to_cmdliner (type a) (t: a t) (f: a -> _) =
    let i = cmdliner_of_info t.info in
    match t.kind with
    | Flag     -> Cmdliner.Term.(app @@ pure f) Cmdliner.Arg.(value @@ flag i)
    | Opt desc ->
      let f_desc v z = match v with
        | Some v -> f v z
        | None -> z
      in
      let none = Fmt.strf "%a" (pp_conv desc) t.default in
      Cmdliner.Term.(app @@ pure f_desc)
        Cmdliner.Arg.(value @@ opt (some ~none @@ converter desc) None i)

  let serialize_default (type a) ?default ppf (t: a t) =
    let default = match default with
      | None   -> t.default
      | Some d -> d
    in
    match t.kind with
    | Flag  -> (serialize bool) ppf default
    | Opt c -> (serialize c) ppf default

  let serialize (type a): ?default:a -> a t serialize = fun ?default ppf t ->
    let default = match default with
      | None   -> t.default
      | Some d -> d
    in
    match t.kind with (* FIXME: passing a default to flag does not make sense *)
    | Flag  -> Fmt.pf ppf "Functoria_runtime.Arg.flag %a" serialize_info t.info
    | Opt c -> Fmt.pf ppf "Functoria_runtime.Arg.opt %s %a %a"
                 (runtime_conv c) (serialize c) default serialize_info t.info

end

type 'a key = {
  name   : string;
  arg    : 'a Arg.t;
  key    : 'a Univ.key;
  setters: 'a setter list;
}

and -'a setter = Setter: 'b key * ('a -> 'b option) -> 'a setter

module Set = struct
  type elt = Any: 'a key -> elt
  module M = struct
    type t = elt
    let compare (Any k1) (Any k2) = String.compare k1.name k2.name
  end
  include (Set.Make(M): Set.S with type elt := elt)

  (* FIXME(samoht): do we need this? *)
  let _add k set =
    if mem k set then
      if k != find k set then
        let Any k' = k in
        Log.fail "Duplicate key name: %S" k'.name
      else
        set
    else
      add k set

  let pp = Fmt.iter ~sep:(Fmt.unit ",@ ") iter

end

type t = Set.elt = Any: 'a key -> t
let compare = Set.M.compare

module Alias = struct

  type 'a t = {
    a_setters: 'a setter list;
    a_arg    : 'a Arg.t;
  }

  let setters t = t.a_setters
  let arg t = t.a_arg
  let create a_arg = { a_setters = []; a_arg }
  let flag doc = create (Arg.flag ~stage:`Configure doc)
  let opt conv d i = create (Arg.opt ~stage:`Configure conv d i)
  let add k f t = { t with a_setters = Setter (k, f) :: t.a_setters }

  let apply_one v map (Setter (k,f)) = match f v with
    | None   -> map
    | Some v ->
      if Univ.mem k.key map then map
      else Univ.add k.key v map

  let apply v l map = List.fold_left (apply_one v) map l
  let keys l = Set.of_list @@ List.map (fun (Setter (k,_)) -> Any k) l

end

let v x = Any x
let arg k = k.arg
let aliases (Any k) = Set.elements @@ Alias.keys k.setters
let name (Any k) = k.name
let stage (Any k) = Arg.stage k.arg

let is_runtime k = match stage k with
  | `Run | `Both -> true
  | `Configure -> false

let is_configure k = match stage k with
  | `Configure | `Both -> true
  | `Run -> false

let filter_stage stage l = match stage with
  | `Run    -> List.filter is_runtime l
  | `Configure
  | `NoEmit -> List.filter is_configure l
  | `Both   -> l

(* Key Map *)

type context = Univ.t

let get ctx t = match Univ.find t.key ctx with
  | Some x -> x
  | None   -> Arg.default t.arg

let mem_u ctx t = Univ.mem t.key ctx

(* {2 Values} *)

type +'a value = { deps: Set.t; v: context -> 'a }

let eval p v = v.v p
let pure x = { deps = Set.empty; v = fun _ -> x }

let app f x = {
  deps = Set.union f.deps x.deps;
  v = fun p -> (eval p f) (eval p x);
}

let map f x = app (pure f) x
let pipe x f = map f x
let if_ c t e = pipe c @@ fun b -> if b then t else e
let match_ v f = map f v
let ($) = app
let value k = let v p = get p k in { deps = Set.singleton (Any k); v }
let with_deps ~keys v = { v with deps = Set.(union v.deps @@ Set.of_list keys) }
let deps k = Set.elements k.deps
let mem p v = Set.for_all (fun (Any x) -> mem_u p x) v.deps
let peek p v = if mem p v then Some (eval p v) else None
let default v = eval Univ.empty v

(* {2 Pretty printing} *)

let pp fmt k = Fmt.string fmt (name k)
let pp_deps fmt v = Set.pp pp fmt v.deps

let pps p =
  let f fmt (Any k) =
    let default = if mem_u p k then Fmt.nop else Fmt.unit " (default)" in
    Fmt.pf fmt "%a=%a%a"
      Fmt.(styled `Bold string) k.name (Arg.pp k.arg) (get p k) default ()
  in
  fun ppf l -> Set.(pp f ppf @@ of_list l)

(* {2 Automatic documentation} *)

let info_setters setters (info: Arg.info) =
  let f fmt k = Fmt.pf fmt "$(b,%s)" (name k) in
  let doc_s = if setters = [] then "" else
      Fmt.strf "\nWill automatically set the following keys: %a."
        (Set.pp f) (Alias.keys setters)
  in
  let doc = match info.Arg.doc with
    | None -> doc_s
    | Some s -> s ^ doc_s
  in
  { info with Arg.doc = Some doc }

(* {2 Key creation} *)

let alias name a =
  let setters = Alias.setters a in
  let arg = Alias.arg a in
  let arg = { arg with Arg.info = info_setters setters arg.Arg.info } in
  let key = Univ.new_key name in
  { setters; arg; name; key }

let create name arg =
  let key = Univ.new_key name in
  let setters = [] in
  { setters; arg; name; key }

(* {2 Cmdliner interface} *)

let parse_key t = Arg.to_cmdliner t.arg

let context ?(stage=`Both) l =
  let gather (Any k) rest =
    let f v p = Alias.apply v k.setters (Univ.add k.key v p) in
    Cmdliner.Term.(parse_key k f $ rest)
  in
  List.fold_right gather (filter_stage stage l) (Cmdliner.Term.pure Univ.empty)

(*
let parse_value ?stage t =
  let deps = Set.elements t.deps in
  Cmdliner.Term.(pure t.v $ context ?stage deps)
*)

(* {2 Code emission} *)

let module_name = "Bootvar_gen"
let ocaml_name k = Name.ocamlify (name k)
let serialize_call fmt k = Fmt.pf fmt "(%s.%s ())" module_name (ocaml_name k)
let serialize ctx ppf (Any k) = Arg.serialize ppf ~default:(get ctx k) (arg k)
let name (Any k) = k.name

let serialize_rw ctx fmt t =
  Format.fprintf fmt
    "@[<2>let %s =@,Functoria_runtime.Key.create@ %S@ @[(%a)@]@]@,\
     @[<2>let %s_t =@ Functoria_runtime.Key.term %s@]@,\
     @[<2>let %s () =@ Functoria_runtime.Key.get %s@]@,"
    (ocaml_name t)  (name t) (serialize ctx) t
    (ocaml_name t) (ocaml_name t)
    (ocaml_name t) (ocaml_name t)

let serialize_ro ctx fmt t =
  let Any k = t in
  Format.fprintf fmt "@[<2>let %s () =@ %a@]@," (ocaml_name t)
    (Arg.serialize_default ~default:(get ctx k)) (arg k)

let serialize ctx fmt k =
  if is_runtime k
  then serialize_rw ctx fmt k
  else serialize_ro ctx fmt k
