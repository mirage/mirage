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

  type 'a parser = string -> [ `Ok of 'a | `Error of string ]
  type 'a printer = Format.formatter -> 'a -> unit
  type 'a converter = 'a parser * 'a printer

  type 'a t = {
    description : string ;
    serializer : Format.formatter -> 'a -> unit ;
    converter : 'a converter ;
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

  let from_converter description converter =
    { description ; converter ; serializer = snd converter }

end

type stage = [
  | `Configure
  | `Run
  | `Both
]

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

type 'a key = {
  name : string ;
  stage : stage ;
  doc : Doc.t ;
  desc : 'a Desc.t ;
  default : 'a ;
  mutable value : 'a option ;
}

let create ?doc ?(stage=`Both) ~default name desc =
  let docv = String.uppercase name in
  let doc = Doc.create ~docv ?doc [name] in
  { doc; name; value = None ; default ; desc ; stage }

let create_raw ~doc ~stage ~default name desc =
  { doc ; stage ; default ; desc ; value = None ; name }

let desc k = k.desc

let get k = match k.value with
  | None -> k.default
  | Some v -> v

let set k x =
  k.value <- Some x


module M = struct
  type t = Any : 'a key -> t
  let compare (Any k1) (Any k2) = compare k1.name k2.name
end
include M

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

let resolved { value } = value <> None

module Set = struct
  include Set.Make (M)

  let add k set =
    if mem k set then
      if k != find k set then
        let Any k' = k in
        fail "Duplicate key name: %S" k'.name
      else
        set
    else
      add k set

  let filter_stage ~stage set =
    match stage with
    | `Run -> filter is_runtime set
    | `Configure -> filter is_configure set
    | `Both -> set
end



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
  Set.fold gather (Set.filter_stage ~stage l) (Term.pure ())



let serialize fmt (Any k) =
  let v = get k in
  Format.fprintf fmt "%a" (Desc.serializer @@ desc k) v

let describe fmt (Any { desc ; _ }) =
  Format.fprintf fmt "%s" desc.description


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

let ($) = app


let value k =
  let v () =
    match k.value with
    | None -> k.default
    | Some s -> s
  in
  { deps = Set.singleton (Any k) ; v }

let deps k = k.deps

let peek { deps ; v } =
  if Set.for_all (fun (Any x) -> resolved x) deps then Some (v ()) else None



exception Illegal of string

let ocamlify s =
  let b = Buffer.create (String.length s) in
  String.iter begin function
    | 'a'..'z' | 'A'..'Z'
    | '0'..'9' | '_' as c -> Buffer.add_char b c
    | '-' -> Buffer.add_char b '_'
    | _ -> ()
  end s;
  let s' = Buffer.contents b in
  if String.length s' = 0 || ('0' <= s'.[0] && s'.[0] <= '9') then raise (Illegal s);
  s'

let ocaml_name k = ocamlify (name k)
let pp_meta fmt k =
  Fmt.pf fmt "(%s ())" (ocaml_name k)

let emit fmt k =
  Format.fprintf fmt
    "let %s = Functoria_runtime.Key.create ~doc:%a ~default:%a %a\n\
     let %s_t = Functoria_runtime.Key.term %s\n\
     let %s () = Functoria_runtime.Key.get %s@\n"
    (ocaml_name k)   Doc.emit (doc k)  serialize k  describe k
    (ocaml_name k)  (ocaml_name k)
    (ocaml_name k)  (ocaml_name k)

let pp fmt k = Fmt.string fmt (name k)

let pp_deps fmt v =
  Fmt.(iter Set.iter ~sep:(unit ", ") pp) fmt v.deps
