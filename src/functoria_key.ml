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

  type 'a converter = {
    configure: 'a Cmdliner.Arg.converter;
    emit     : Format.formatter -> 'a -> unit;
    runtime  : string;
  }

  let conv configure emit runtime = { configure; emit; runtime }

  let string = {
    configure = Cmdliner.Arg.string;
    emit      = (fun fmt -> Format.fprintf fmt "%S");
    runtime   = "Cmdliner.Arg.string";
  }

  let bool = {
    configure  = Cmdliner.Arg.bool;
    emit       = (fun fmt -> Format.fprintf fmt "%b");
    runtime    ="Cmdliner.Arg.bool";
  }

  let int = {
    configure = Cmdliner.Arg.int;
    emit      = (fun fmt -> Format.fprintf fmt "%i");
    runtime   = "Cmdliner.Arg.int";
  }

  let list d = {
    configure = Cmdliner.Arg.list d.configure;
    emit      = Emit.list d.emit;
    runtime   = Fmt.strf "(Cmdliner.Arg.list %s)" d.runtime;
  }

  let some d = {
    configure = Cmdliner.Arg.some d.configure;
    emit      = Emit.option d.emit;
    runtime   = Fmt.strf "(Cmdliner.Arg.some %s)" d.runtime;
  }

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

  type 'a t =
    | Opt : 'a converter -> 'a t
    | Flag: bool t

  let pp: type a . a t -> a Fmt.t = function
    | Opt c -> snd c.configure
    | Flag  -> Fmt.bool

  let at_configure (type a) ~default ~info:i (t: a t) (f :a -> _) =
    let f_desc v z = match v with
      | Some v -> f v z
      | None -> z
    in
    match t with
    | Flag     -> Cmdliner.Term.(app @@ pure f) Cmdliner.Arg.(value @@ flag i)
    | Opt desc ->
      let none = Fmt.strf "%a" (snd desc.configure) default in
      Cmdliner.Term.(app @@ pure f_desc)
        Cmdliner.Arg.(value @@ opt (some ~none desc.configure) None i)

  let at_runtime: type a . a t -> _ = function
    | Flag  -> "Functoria_runtime.Conv.flag"
    | Opt c -> Fmt.strf "(Functoria_runtime.Conv.opt %s)" c.runtime

  let emit: type a . a t -> a Fmt.t = function
    | Flag  -> Fmt.fmt "%b"
    | Opt c -> c.emit

end

type stage = [
  | `Configure
  | `Run
  | `Both
]

type 'a key = {
  name   : string;
  stage  : stage;
  info   : Arg.info;
  arg    : 'a Arg.t;
  default: 'a;
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

  let add k set =
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

module Setters = struct
  type 'a t = 'a setter list
  let empty = []
  let add k f setters = Setter (k, f) :: setters

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
let setters (Any k) = Setters.keys k.setters
let name (Any k) = k.name
let stage (Any k) = k.stage
let info (Any k) = k.info

let is_runtime k = match stage k with
  | `Run | `Both -> true
  | `Configure -> false

let is_configure k = match stage k with
  | `Configure | `Both -> true
  | `Run -> false

let filter_stage ~stage set =
  match stage with
  | `Run -> Set.filter is_runtime set
  | `Configure | `NoEmit -> Set.filter is_configure set
  | `Both -> set

(* Key Map *)

type parsed = Univ.t

let get map { key; default; _ } = match Univ.find key map with
  | Some x -> x
  | None   -> default

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
let with_deps ~keys { deps; v } = { deps = Set.(union deps keys); v }
let value k = let v p = get p k in { deps = Set.singleton (Any k); v }
let deps k = k.deps
let is_resolved p v = Set.for_all (fun (Any x) -> mem p x) v.deps
let peek p v = if is_resolved p v then Some (eval p v) else None
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
  Set.pp f

(* {2 Automatic documentation} *)

let info_setters setters (info: Arg.info) =
  let f fmt k = Fmt.pf fmt "$(b,%s)" (name k) in
  let doc_s = if setters = [] then "" else
      Fmt.strf "\nWill automatically set the following keys: %a."
        (Set.pp f) (Setters.keys setters)
  in
  let doc = match info.Arg.doc with
    | None -> doc_s
    | Some s -> s ^ doc_s
  in
  { info with Arg.doc = Some doc }

(* {2 Key creation} *)

(* Use internally only *)
let create_raw ~stage ~setters ~doc ~default ~name ~arg =
  let key = Univ.new_key name in
  let info = info_setters setters doc in
  { info; stage; default; setters; arg; name; key }

(* Use internally only *)
let flag_raw ~stage ~setters ~doc ~name =
  create_raw ~stage ~setters ~doc ~default:false ~name ~arg:Arg.Flag

let create ?(stage=`Both) ~doc ~default name arg =
  let setters = Setters.empty in
  let arg = Arg.Opt arg in
  create_raw ~stage ~setters ~doc ~default ~name ~arg

let flag ?(stage=`Both) ~doc name =
  let setters = Setters.empty in
  flag_raw ~stage ~setters ~doc ~name

let proxy ~doc ~setters name =
  flag_raw ~setters ~doc ~stage:`Configure ~name

(* {2 Cmdliner interface} *)

let term_key { info; arg; default; _ } =
  let info = Arg.info_at_configure info in
  Arg.at_configure ~default ~info arg

let term ?(stage=`Both) l =
  let gather (Any k) rest =
    let f v p = Setters.apply v k.setters (Univ.add k.key v p) in
    Cmdliner.Term.(term_key k f $ rest)
  in
  Set.fold gather (filter_stage ~stage l) (Cmdliner.Term.pure Univ.empty)

let term_value ?stage { deps; v } = Cmdliner.Term.(pure v $ term ?stage deps)

(* {2 Code emission} *)

let module_name = "Bootvar_gen"

let emit p fmt (Any k) =
  Format.fprintf fmt "%a" (Arg.emit @@ arg k) @@ get p k

let at_runtime fmt (Any { arg; _ }) =
  Format.fprintf fmt "%s" (Arg.at_runtime arg)

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
