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

  (** {1 Converters} *)

  type 'a serialize = Format.formatter -> 'a -> unit
  type 'a runtime_conv = string

  type 'a converter = {
    conv: 'a Cmdliner.Arg.converter;
    serialize: 'a serialize;
    runtime_conv: 'a runtime_conv;
  }

  let conv ~conv ~serialize ~runtime_conv = { conv; serialize; runtime_conv }

  let converter x = x.conv
  let serialize x = x.serialize
  let runtime_conv x = x.runtime_conv

  let string = conv
      ~conv:Cmdliner.Arg.string ~runtime_conv:"Cmdliner.Arg.string"
      ~serialize:(fun fmt -> Format.fprintf fmt "%S")

  let bool = conv
      ~conv:Cmdliner.Arg.bool ~runtime_conv:"Cmdliner.Arg.bool"
      ~serialize:(fun fmt -> Format.fprintf fmt "%b")

  let int = conv
      ~conv:Cmdliner.Arg.int ~runtime_conv:"Cmdliner.Arg.int"
      ~serialize:(fun fmt -> Format.fprintf fmt "%i")

  let list d = conv
      ~conv:(Cmdliner.Arg.list (converter d))
      ~runtime_conv:(Fmt.strf "(Cmdliner.Arg.list %s)" (runtime_conv d))
      ~serialize:(Serialize.list (serialize d))

  let some d = conv
      ~conv:(Cmdliner.Arg.some (converter d))
      ~runtime_conv:(Fmt.strf "(Cmdliner.Arg.some %s)" (runtime_conv d))
      ~serialize:(Serialize.option (serialize d))

  (** {1 Information about arguments} *)

  type info = {
    doc  : string option;
    docs : string;
    docv : string option;
    names: string list;
    env  : string option;
  }

  let info ?(docs="APPLICATION OPTIONS") ?docv ?doc ?env names =
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

  (** {1 Arguments} *)

  type 'a kind =
    | Opt : 'a * 'a converter -> 'a kind
    | Required : 'a converter -> 'a option kind
    | Flag: bool kind

  type stage = [
    | `Configure
    | `Run
    | `Both
  ]

  let pp_conv c = snd (converter c)

  let pp_kind: type a . a kind -> a Fmt.t = function
    | Opt (_, c) -> pp_conv c
    | Required c -> pp_conv (some c)
    | Flag       -> Fmt.bool

  type 'a t = {
    stage  : stage;
    info   : info;
    kind   : 'a kind;
  }

  let pp t = pp_kind t.kind
  let stage t = t.stage

  let opt ?(stage=`Both) conv default info =
    { stage; info; kind = Opt (default, conv) }

  let flag ?(stage=`Both) info =
    { stage; info; kind = Flag }

  let required ?(stage=`Both) conv info =
    { stage; info; kind = Required conv }

  let make_opt_cmdliner wrap i default f desc =
    let none = match default with
      | Some d -> Some (Fmt.strf "%a" (pp_conv desc) d)
      | None -> None
    in
    let f_desc v z = match v with
      | Some v -> f v z
      | None -> z
    in
    Cmdliner.Term.(app @@ pure f_desc)
      Cmdliner.Arg.(wrap @@ opt (some ?none @@ converter desc) None i)

  let to_cmdliner ~with_required (type a) (t: a t) (f: a -> _) =
    let i = cmdliner_of_info t.info in
    match t.kind with
    | Flag -> Cmdliner.Term.(app @@ pure f) Cmdliner.Arg.(value @@ flag i)
    | Opt (default, desc) ->
      make_opt_cmdliner Cmdliner.Arg.value i (Some default) f desc
    | Required desc when with_required && t.stage = `Configure ->
      make_opt_cmdliner Cmdliner.Arg.required i None f (some (some desc))
    | Required desc ->
      make_opt_cmdliner Cmdliner.Arg.value i None f (some desc)

  let serialize_value (type a) (v:a) ppf (t: a t) =
    match t.kind with
    | Flag       -> (serialize bool) ppf v
    | Opt (_, c) -> (serialize c) ppf v
    | Required c -> match v with
      | Some v -> (serialize c) ppf v
      | None -> assert false
        (* This is only called by serialize_ro, hence a configure time
           key, so the value is known. *)

  let serialize (type a): a -> a t serialize = fun v ppf t ->
    match t.kind with
    | Flag -> Fmt.pf ppf "Functoria_runtime.Arg.flag %a" serialize_info t.info
    | Opt (_, c) ->
      Fmt.pf ppf "Functoria_runtime.Arg.opt %s %a %a"
        (runtime_conv c) (serialize c) v serialize_info t.info
    | Required c ->
      Fmt.pf ppf "Functoria_runtime.Arg.key ?default:(%a) %s %a"
        (serialize @@ some c) v (runtime_conv c) serialize_info t.info

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

  let add k set =
    if mem k set then
      if k != find k set then
        let Any k' = k in
        invalid_arg ("Duplicate key name: " ^ k'.name)
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
  (* let opt conv d i = create (Arg.opt ~stage:`Configure conv d i) *)
  let add k f t = { t with a_setters = Setter (k, f) :: t.a_setters }

  let apply_one v map (Setter (k,f)) = match f v with
    | None   -> map
    | Some v ->
      if Univ.mem k.key map then map
      else Univ.add k.key v map

  let apply v l map = List.fold_left (apply_one v) map l
  let keys l = Set.of_list @@ List.map (fun (Setter (k,_)) -> Any k) l

end

let abstract x = Any x
let arg k = k.arg
let aliases (Any k) = Alias.keys k.setters
let name (Any k) = k.name
let stage (Any k) = Arg.stage k.arg

let is_runtime k = match stage k with
  | `Run | `Both -> true
  | `Configure -> false

let is_configure k = match stage k with
  | `Configure | `Both -> true
  | `Run -> false

let filter_stage stage s = match stage with
  | `Run    -> Set.filter is_runtime s
  | `Configure
  | `NoEmit -> Set.filter is_configure s
  | `Both   -> s

(* Key Map *)

type context = Univ.t
let empty_context = Univ.empty
let merge_context = Univ.merge

let get (type a) ctx (t : a key) : a =
  match t.arg.Arg.kind, Univ.find t.key ctx with
  | Arg.Required _ , Some (Some x) -> Some x
  | Arg.Required _ , (None | Some None) -> None
  | Arg.Flag , Some x -> x
  | Arg.Opt _, Some x -> x
  | Arg.Opt (d,_), None -> d
  | Arg.Flag, None -> false

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
let value k = let v c = get c k in { deps = Set.singleton (Any k); v }
let of_deps deps = {(pure ()) with deps}
let deps k = k.deps
let mem p v = Set.for_all (fun (Any x) -> mem_u p x) v.deps
let peek p v = if mem p v then Some (eval p v) else None
let default v = eval Univ.empty v

(* {2 Pretty printing} *)

let dump_context = Univ.dump
let pp fmt k = Fmt.string fmt (name k)
let pp_deps fmt v = Set.pp pp fmt v.deps

let pps p =
  let pp' fmt k v =
    let default = if mem_u p k then Fmt.nop else Fmt.unit " (default)" in
    Fmt.pf fmt "%a=%a%a"
      Fmt.(styled `Bold string) k.name
      (Arg.pp k.arg) v
      default ()
  in
  let f fmt (Any k) = match k.arg.Arg.kind, get p k with
    | Arg.Required _, None ->
      Fmt.(styled `Bold string) fmt k.name
    | Arg.Opt _ ,v     -> pp' fmt k v
    | Arg.Required _,v -> pp' fmt k v
    | Arg.Flag ,v      -> pp' fmt k v
    (* Warning 4 and GADT don't interact well. *)
  in
  fun ppf s -> Set.(pp f ppf @@ s)

(* {2 Automatic documentation} *)

let info_alias setters =
  let f fmt k = Fmt.pf fmt "$(b,%s)" (name k) in
  match setters with
  | [] -> ""
  | [ _ ] ->
    Fmt.strf "Will automatically set %a." (Set.pp f) (Alias.keys setters)
  | _ ->
    Fmt.strf "Will automatically set the following keys: %a."
      (Set.pp f) (Alias.keys setters)

let info_arg (type a) (arg: a Arg.kind) = match arg with
  | Arg.Required _ -> "This key is required."
  | Arg.Flag -> ""
  | Arg.Opt _ -> ""

let add_extra_info setters arg =
  match arg.Arg.info.doc with
  | None -> arg
  | Some doc ->
    let doc = String.concat " " [
        doc ;
        info_alias setters ;
        info_arg arg.kind ;
      ]
    in
    {arg with info = {arg.info with doc = Some doc}}

(* {2 Key creation} *)

(* Unexposed smart constructor. *)
let make ~setters ~arg ~name =
  let key = Univ.new_key name in
  let arg = add_extra_info setters arg in
  { setters ; arg ; name ; key }

let alias name a =
  let setters = Alias.setters a in
  let arg = Alias.arg a in
  make ~setters ~arg ~name

let create name arg =
  let setters = [] in
  make ~setters ~arg ~name

(* {2 Cmdliner interface} *)

let parse_key t = Arg.to_cmdliner t.arg

let context ?(stage=`Both) ~with_required l =
  let gather (Any k) rest =
    let f v p = Alias.apply v k.setters (Univ.add k.key v p) in
    Cmdliner.Term.(parse_key ~with_required k f $ rest)
  in
  Set.fold gather (filter_stage stage l) (Cmdliner.Term.pure empty_context)

(* {2 Code emission} *)

let module_name = "Key_gen"
let ocaml_name k = Name.ocamlify (name k)
let serialize_call fmt k = Fmt.pf fmt "(%s.%s ())" module_name (ocaml_name k)
let serialize ctx ppf (Any k) = Arg.serialize (get ctx k) ppf (arg k)

let serialize_rw ctx fmt t =
  Format.fprintf fmt
    "@[<2>let %s =@,Functoria_runtime.Key.create@ %a@]@,\
     @[<2>let %s_t =@ Functoria_runtime.Key.term %s@]@,\
     @[<2>let %s () =@ Functoria_runtime.Key.get %s@]@,"
    (ocaml_name t) Fmt.(parens (serialize ctx)) t
    (ocaml_name t) (ocaml_name t)
    (ocaml_name t) (ocaml_name t)

let serialize_ro ctx fmt t =
  let Any k = t in
  Format.fprintf fmt "@[<2>let %s () =@ %a@]@," (ocaml_name t)
    (Arg.serialize_value (get ctx k)) (arg k)

let serialize ctx fmt k =
  if is_runtime k
  then serialize_rw ctx fmt k
  else serialize_ro ctx fmt k
