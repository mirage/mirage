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

module Emit = struct
  let string fmt s = Format.fprintf fmt "%S" s
  let option x = Fmt.(parens @@ Dump.option x)
  let list x = Fmt.Dump.list x
end

module Arg = struct

  type 'a emitter = Format.formatter -> 'a -> unit
  type 'a code = string
  type 'a converter = 'a Cmdliner.Arg.converter * 'a emitter * 'a code

  let conf (x, _, _) = x
  let emit (_, x, _) = x
  let run (_, _, x) = x

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
    Cmdliner.Arg.list (conf d),
    Emit.list (emit d),
    Fmt.strf "(Cmdliner.Arg.list %s)" (run d)

  let some d =
    Cmdliner.Arg.some (conf d),
    Emit.option (emit d),
    Fmt.strf "(Cmdliner.Arg.some %s)" (run d)

  type info = {
    doc  : string option;
    docs : string;
    docv : string option;
    names: string list;
    env  : string option;
  }

  let info ?(docs="UNIKERNEL PARAMETERS") ?docv ?doc ?env names =
    { doc; docs; docv; names; env }

  let info_at_configure { docs; docv; doc; env; names } =
    let env = match env with
      | Some s -> Some (Cmdliner.Arg.env_var s)
      | None   -> None
    in
    Cmdliner.Arg.info ~docs ?docv ?doc ?env names

  let emit_env fmt = Fmt.pf fmt "(Cmdliner.Arg.env_var %a)" Emit.string

  let info_emit fmt { docs; docv; doc; env; names } =
    Format.fprintf fmt
      "(Cmdliner.Arg.info@ ~docs:%a@ ?docv:%a@ ?doc:%a@ ?env:%a@ %a)"
      Emit.string docs
      Emit.(option string) docv
      Emit.(option string) doc
      Emit.(option emit_env) env
      Emit.(list string) names

  type 'a kind =
    | Opt : 'a converter -> 'a kind
    | Flag: bool kind

  let pp_kind: type a . a kind -> a Fmt.t = function
    | Opt c -> snd (conf c)
    | Flag  -> Fmt.bool

  let kind_at_configure (type a) ~default ~info:i (t: a kind) (f :a -> _) =
    let f_desc v z = match v with
      | Some v -> f v z
      | None -> z
    in
    match t with
    | Flag     -> Cmdliner.Term.(app @@ pure f) Cmdliner.Arg.(value @@ flag i)
    | Opt desc ->
      let none = Fmt.strf "%a" (snd (conf desc)) default in
      Cmdliner.Term.(app @@ pure f_desc)
        Cmdliner.Arg.(value @@ opt (some ~none (conf desc)) None i)

  let kind_at_runtime: type a . a kind -> _ = function
    | Flag  -> "Functoria_runtime.Conv.flag"
    | Opt c -> Fmt.strf "(Functoria_runtime.Conv.opt %s)" (run c)

  let kind_emit: type a . a kind -> a Fmt.t = function
    | Flag  -> Fmt.fmt "%b"
    | Opt c -> (emit c)

  type stage = [
    | `Configure
    | `Run
    | `Both
  ]

  type 'a t = {
    stage  : stage;
    default: 'a;
    info   : info;
    kind   : 'a kind;
  }

  let pp t = pp_kind t.kind

  let stage t = t.stage
  let get_info t = t.info
  let kind t = t.kind
  let default t = t.default

  let opt ?(stage=`Both) conv default info =
    { stage; info; default; kind = Opt conv }

  let flag ?(stage=`Both) info =
    { stage; info; default = false; kind = Flag }

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
  include (Set_Make (M): SET with type elt := elt)

  (* FIXME(samoht): do we need this? *)
  let _add k set =
    if mem k set then
      if k != find k set then
        let Any k' = k in
        fail "Duplicate key name: %S" k'.name
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
let info (Any k) = Arg.get_info k.arg

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

type parsed = Univ.t

let get map { key; arg; _ } = match Univ.find key map with
  | Some x -> x
  | None   -> Arg.default arg

let mem map t = Univ.mem t.key map

(* {2 Values} *)

type +'a value = { deps: Set.t; v: parsed -> 'a }

let eval p v = v.v p
let pure x = { deps = Set.empty; v = fun _ -> x }

let app f x = {
  deps = Set.union f.deps x.deps;
  v = fun p -> (eval p f) (eval p x);
}

let map f x = app (pure f) x
let pipe x f = map f x
let if_ c t e = pipe c @@ fun b -> if b then t else e
let ($) = app
let value k = let v p = get p k in { deps = Set.singleton (Any k); v }
let with_deps ~keys v = { v with deps = Set.(union v.deps @@ Set.of_list keys) }
let deps k = Set.elements k.deps
let is_parsed p v = Set.for_all (fun (Any x) -> mem p x) v.deps
let peek p v = if is_parsed p v then Some (eval p v) else None
let default v = eval Univ.empty v

(* {2 Pretty printing} *)

let pp fmt k = Fmt.string fmt (name k)
let pp_deps fmt v = Set.pp pp fmt v.deps

let pp_parsed p =
  let f fmt (Any k) =
    let default = if mem p k then Fmt.nop else Fmt.unit " (default)" in
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

let parse_key { arg; _ } =
  let default = Arg.default arg in
  let info = Arg.info_at_configure @@ Arg.get_info arg in
  Arg.kind_at_configure ~default ~info arg.Arg.kind

let parse ?(stage=`Both) l =
  let gather (Any k) rest =
    let f v p = Alias.apply v k.setters (Univ.add k.key v p) in
    Cmdliner.Term.(parse_key k f $ rest)
  in
  List.fold_right gather (filter_stage stage l) (Cmdliner.Term.pure Univ.empty)

let parse_value ?stage { deps; v } =
  let deps = Set.elements deps in
  Cmdliner.Term.(pure v $ parse ?stage deps)

(* {2 Code emission} *)

let module_name = "Bootvar_gen"

let emit p fmt (Any k) =
  Format.fprintf fmt "%a" (Arg.kind_emit @@ Arg.kind @@ arg k) @@ get p k

let at_runtime fmt (Any { arg; _ }) =
  Format.fprintf fmt "%s" @@ Arg.kind_at_runtime @@ Arg.kind arg

let ocaml_name k = Name.ocamlify (name k)

let emit_call fmt k =
  Fmt.pf fmt "(%s.%s ())" module_name (ocaml_name k)

let emit_rw p fmt k =
  Format.fprintf fmt
    "@[<2>let %s =@ Functoria_runtime.Key.create@ ~doc:%a@ ~default:%a %a@]@,\
     @[<2>let %s_t =@ Functoria_runtime.Key.term %s@]@,\
     @[<2>let %s () =@ Functoria_runtime.Key.get %s@]@,"
    (ocaml_name k)  Arg.info_emit (info k) (emit p) k at_runtime k
    (ocaml_name k)  (ocaml_name k)
    (ocaml_name k)  (ocaml_name k)

let emit_ro map fmt k =
  Format.fprintf fmt "@[<2>let %s () =@ %a@]@," (ocaml_name k) (emit map) k

let emit map fmt k =
  if is_runtime k
  then emit_rw map fmt k
  else emit_ro map fmt k
