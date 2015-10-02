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
open Cmdliner

module Emit = struct

  let string fmt s = Format.fprintf fmt "%S" s

  let option x = Fmt.(parens @@ Dump.option x)

  let list x = Fmt.Dump.list x

end

module Desc = struct

  type 'a t = {
    description : string ;
    serializer : Format.formatter -> 'a -> unit ;
    converter : 'a Cmdliner.Arg.converter ;
  }

  let serializer d = d.serializer
  let description d = d.description
  let converter d = d.converter

  let create ~serializer ~converter ~description =
    { description ; serializer ; converter }

  module C = Functoria_runtime.Converter
  let from_run s = "Functoria_runtime.Converter." ^ s

  let string = {
    description = from_run "string" ;
    serializer = (fun fmt -> Format.fprintf fmt "%S") ;
    converter = C.string ;
  }

  let bool = {
    description = from_run "bool" ;
    serializer = (fun fmt -> Format.fprintf fmt "%b") ;
    converter = C.bool ;
  }

  let int = {
    description = from_run "int" ;
    serializer = (fun fmt -> Format.fprintf fmt "%i") ;
    converter = C.int ;
  }

  let list d = {
    description = Fmt.strf "(%s %s)" (from_run "list") d.description ;
    serializer = Emit.list d.serializer ;
    converter = C.list d.converter ;
  }

  let option d = {
    description = Fmt.strf "(%s %s)" (from_run "option") d.description ;
    serializer = Emit.option d.serializer ;
    converter = C.option d.converter
  }

end

module Doc = struct

  type t = {
    doc : string option ;
    docs : string ;
    docv : string option ;
    names : string list ;
    env : string option ;
  }

  let create ?(docs="UNIKERNEL PARAMETERS") ?docv ?doc ?env names =
    { doc ; docs ; docv ; names ; env }

  let to_cmdliner { docs ; docv ; doc ; env ; names } =
    let env = match env with
      | Some s -> Some (Arg.env_var s)
      | None -> None
    in
    Arg.info ~docs ?docv ?doc ?env names

  let emit_env fmt = Fmt.pf fmt "(Cmdliner.Arg.env_var %a)" Emit.string

  let emit fmt { docs ; docv ; doc ; env ; names } =
    Format.fprintf fmt
      "(Cmdliner.Arg.info@ ~docs:%a@ ?docv:%a@ ?doc:%a@ ?env:%a@ %a)"
      Emit.string docs
      Emit.(option string) docv
      Emit.(option string) doc
      Emit.(option emit_env) env
      Emit.(list string) names

end

(** {2 Keys} *)

type stage = [
  | `Configure
  | `Run
  | `Both
]

type 'a key = {
  name : string ;
  stage : stage ;
  doc : Doc.t ;
  desc : 'a Desc.t ;
  default : 'a ;
  key : 'a Univ.key
}

let create ?(stage=`Both) ~doc ~default name desc =
  let key = Univ.new_key name in
  { doc ; stage ; default ; desc ; name ; key }

let desc k = k.desc


module Set = struct
  type elt = Any : 'a key -> elt
  module M = struct
    type t = elt
    let compare (Any k1) (Any k2) = String.compare k1.name k2.name
  end
  include (Set_Make (M) : SET with type elt := elt)

  let add k set =
    if mem k set then
      if k != find k set then
        let Any k' = k in
        fail "Duplicate key name: %S" k'.name
      else
        set
    else
      add k set

end
type t = Set.elt = Any : 'a key -> t

let hidden x = Any x
let name (Any k) = k.name
let stage (Any k) = k.stage
let doc (Any k) = k.doc

let is_runtime k = match stage k with
  | `Run | `Both -> true
  | `Configure -> false

let is_configure k = match stage k with
  | `Configure | `Both -> true
  | `Run -> false

let filter_stage ~stage set =
  match stage with
  | `Run -> Set.filter is_runtime set
  | `Configure -> Set.filter is_configure set
  | `Both -> set


(** Key Map *)

type map = Univ.t

let get map { key ; default } =
  match Univ.find key map with
  | Some x -> x
  | None -> default

let mem map t = Univ.mem t.key map

(** {2 Values} *)

type +'a value = {
  deps : Set.t ;
  v : map -> 'a ;
}

let eval map { v } = v map

let pure x = { deps = Set.empty ; v = fun _ -> x }
let app f x = {
  deps = Set.union f.deps x.deps ;
  v = fun map -> (eval map f) (eval map x) ;
}

let map f x = app (pure f) x
let pipe x f = map f x
let if_ c t e =
  pipe c @@ fun b -> if b then t else e

let ($) = app
let with_deps ~keys { deps ; v } =
  { deps = Set.(union deps keys) ; v }

let value k =
  let v map = get map k in
  { deps = Set.singleton (Any k) ; v }

let deps k = k.deps

let is_resolved map { deps } =
  Set.for_all (fun (Any x) -> mem map x) deps

let peek map v =
  if is_resolved map v then Some (eval map v) else None

let default v =
  eval Univ.empty v

(** {2 Pretty printing} *)

let pp fmt k = Fmt.string fmt (name k)

let pp_deps fmt v =
  Fmt.(iter Set.iter ~sep:(unit ", ") pp) fmt v.deps

let pp_map map =
  let f fmt (Any k) =
    let default = if mem map k then Fmt.nop else Fmt.unit " (default)" in
    Fmt.pf fmt "%a=%a%a"
      Fmt.(styled `Bold string) k.name
      (snd k.desc.converter) (get map k)
      default ()
  in
  Fmt.(iter ~sep:(unit ",@ ") Set.iter f)

(** {2 Cmdliner interface} *)

let term_key
  : type a. a key -> a option Term.t
  = fun { doc; desc; default } ->
  let i = Doc.to_cmdliner doc in
  (* We don't want to set the value if the option is not given.
     We still want to show the default value in the help. *)
  let default = Fmt.strf "%a" (snd @@ Desc.converter desc) default in
  let c = Arg.some ~none:default desc.converter in
  Arg.(value & opt c None i)

let term ?(stage=`Both) l =
  let gather (Any k) rest =
    let f v map = match v with
      | Some v -> Univ.add k.key v map
      | None -> map
    in
    Term.(pure f $ term_key k $ rest)
  in
  Set.fold gather (filter_stage ~stage l) (Term.pure Univ.empty)

let term_value ?stage { deps ; v } =
  Term.(pure v $ term ?stage deps)


(** {2 Code emission} *)

let module_name = "Bootvar_gen"

let serialize map fmt (Any k) =
  Format.fprintf fmt "%a" (Desc.serializer @@ desc k) @@ get map k

let describe fmt (Any { desc ; _ }) =
  Format.fprintf fmt "%s" desc.description

let ocaml_name k = Name.ocamlify (name k)

let emit_call fmt k =
  Fmt.pf fmt "(%s.%s ())" module_name (ocaml_name k)

let emit_rw map fmt k =
  Format.fprintf fmt
    "@[<2>let %s =@ Functoria_runtime.Key.create@ ~doc:%a@ ~default:%a %a@]@,\
     @[<2>let %s_t =@ Functoria_runtime.Key.term %s@]@,\
     @[<2>let %s () =@ Functoria_runtime.Key.get %s@]@,"
    (ocaml_name k)   Doc.emit (doc k)  (serialize map) k  describe k
    (ocaml_name k)  (ocaml_name k)
    (ocaml_name k)  (ocaml_name k)

let emit_ro map fmt k =
  Format.fprintf fmt
    "@[<2>let %s () =@ %a@]@,"
    (ocaml_name k)  (serialize map) k

let emit map fmt k =
  if is_runtime k
  then emit_rw map fmt k
  else emit_ro map fmt k
