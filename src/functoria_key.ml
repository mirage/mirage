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
  }

  let create ?(docs="UNIKERNEL PARAMETERS") ?docv ?doc names =
    { doc ; docs ; docv ; names }

  let to_cmdliner { docs ; docv ; doc ; names } =
    Arg.info ~docs ?docv ?doc names

  let emit fmt { docs ; docv ; doc ; names } =
    Format.fprintf fmt
      "(Cmdliner.Arg.info@ ~docs:%a@ ?docv:%a@ ?doc:%a@ %a)"
      Emit.string docs
      Emit.(option string) docv
      Emit.(option string) doc
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
  mutable value : 'a option ;
}

let create ?(stage=`Both) ~doc ~default name desc =
  { doc ; stage ; default ; desc ; value = None ; name }

let desc k = k.desc

let get k = match k.value with
  | None -> k.default
  | Some v -> v

let set k x =
  k.value <- Some x


module Set = struct
  type elt = Any : 'a key -> elt
  module M = struct
    type t = elt
    let compare (Any k1) (Any k2) = compare k1.name k2.name
  end
  include (Set.Make (M) : Set.S with type elt := elt)

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

let hide x = Any x
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

let is_key_resolved { value } = value <> None

(** {2 Values} *)

type +'a value = {
  deps : Set.t ;
  v : unit -> 'a ;
}

let eval { v } = v ()

let pure x = { deps = Set.empty ; v = fun () -> x }
let app f x = {
  deps = Set.union f.deps x.deps ;
  v = fun () -> (eval f) (eval x) ;
}

let map f x = app (pure f) x
let pipe x f = map f x
let if_ c t e =
  pipe c @@ fun b -> if b then t else e

let ($) = app
let with_deps ~keys { deps ; v } =
  { deps = Set.(union deps keys) ; v }

let value k =
  let v () = get k in
  { deps = Set.singleton (Any k) ; v }

let deps k = k.deps

let is_resolved { deps } =
  Set.for_all (fun (Any x) -> is_key_resolved x) deps

let peek v =
  if is_resolved v then Some (v.v ()) else None

(** {2 Pretty printing} *)

let pp fmt k = Fmt.string fmt (name k)

let pp_deps fmt v =
  Fmt.(iter Set.iter ~sep:(unit ", ") pp) fmt v.deps


(** {2 Cmdliner interface} *)

let term_key (Any ({ doc; desc; default } as t)) =
  let i = Doc.to_cmdliner doc in
  (* We don't want to set the value if the option is not given.
     We still want to show the default value in the help. *)
  let default = Fmt.strf "%a" (snd @@ Desc.converter desc) default in
  let c = Arg.some ~none:default desc.converter in
  let set w = t.value <- w in
  Term.(pure set $ Arg.(value & opt c None i))

let term ?(stage=`Both) l =
  let gather k rest = Term.(pure (fun () () -> ()) $ term_key k $ rest) in
  Set.fold gather (filter_stage ~stage l) (Term.pure ())

let term_value ?stage { deps ; v } =
  Term.(pure v $ term ?stage deps)


(** {2 Code emission} *)

let module_name = "Bootvar_gen"

let serialize fmt (Any k) =
  Format.fprintf fmt "%a" (Desc.serializer @@ desc k) @@ get k

let describe fmt (Any { desc ; _ }) =
  Format.fprintf fmt "%s" desc.description

let ocaml_name k = Name.ocamlify (name k)

let emit_call fmt k =
  Fmt.pf fmt "(%s.%s ())" module_name (ocaml_name k)

let emit_rw fmt k =
  Format.fprintf fmt
    "@[<2>let %s =@ Functoria_runtime.Key.create@ ~doc:%a@ ~default:%a %a@]@,\
     @[<2>let %s_t =@ Functoria_runtime.Key.term %s@]@,\
     @[<2>let %s () =@ Functoria_runtime.Key.get %s@]@,"
    (ocaml_name k)   Doc.emit (doc k)  serialize k  describe k
    (ocaml_name k)  (ocaml_name k)
    (ocaml_name k)  (ocaml_name k)

let emit_ro fmt k =
  Format.fprintf fmt
    "@[<2>let %s () =@ %a@]@,"
    (ocaml_name k)  serialize k

let emit fmt k =
  if is_runtime k
  then emit_rw fmt k
  else emit_ro fmt k
