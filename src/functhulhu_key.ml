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

open Functhulhu_misc
open Cmdliner

module Emit = struct

  let string fmt s = Format.fprintf fmt "%S" s

  let list pp =
    let pp_sep = Fmt.(const char ';' <@ sp) in
    Fmt.(brackets @@ list ~pp_sep pp)

  let option f = Fmt.(option ~pp_none:none (parens @@ some f))

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


  let string = {
    description = "Cmdliner.Arg.string" ;
    serializer = (fun fmt -> Format.fprintf fmt "%S") ;
    converter = Arg.string ;
  }

  let list d = {
    description = Format.sprintf "(Cmdliner.Arg.list %s)" d.description ;
    serializer = Emit.list d.serializer ;
    converter = Arg.list d.converter ;
  }

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
    let open Emit in
    Format.fprintf fmt
      "(Cmdliner.Arg.info ~docs:%a ?docv:%a ?doc:%a %a)"
      string docs
      (option string) docv
      (option string) doc
      (list string) names

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


module M = struct
  type t = V : 'a key -> t

  let compare (V k1) (V k2) = compare k1.name k2.name
end
include M

module Set = struct
  include Set.Make (M)

  let add k set =
    if mem k set then
      if k != find k set then
        let V k' = k in
        fail "Duplicate key name: %S" k'.name
      else
        set
    else
      add k set
end

let name (V k) = k.name
let stage (V k) = k.stage
let doc (V k) = k.doc

let is_runtime k = match stage k with
  | `Run | `Both -> true
  | `Configure -> false

let is_configure k = match stage k with
  | `Configure | `Both -> true
  | `Run -> false

let resolved { value } = value <> None



let term_key (V ({ doc; desc; default } as t)) =
  let i = Doc.to_cmdliner doc in
  let c = desc.converter in
  let set w = t.value <- Some w in
  Term.(pure set $ Arg.(value & opt c default i))

let term l =
  let gather k rest = Term.(pure (fun () () -> ()) $ term_key k $ rest) in
  Set.fold gather l (Term.pure ())



let serialize fmt (V k) =
  let v = get k in
  Format.fprintf fmt "%a" (Desc.serializer @@ desc k) v

let describe fmt (V { desc ; _ }) =
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
  { deps = Set.singleton (V k) ; v }

let deps k = k.deps

let peek { deps ; v } =
  if Set.for_all (fun (V x) -> resolved x) deps then Some (v ()) else None



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

let emit fmt k =
  Format.fprintf fmt
    "let %s = Functhulhu_runtime.Key.create ~doc:%a ~default:%a %a\n\
   \ let %s_t = Functhulhu_runtime.Key.term %s\n\
   \ let %s () = Functhulhu_runtime.Key.get %s@\n"
    (ocaml_name k)   Doc.emit (doc k)  serialize k  describe k
    (ocaml_name k)  (ocaml_name k)
    (ocaml_name k)  (ocaml_name k)
