(*
 * Copyright (c) 2015 Nicolas Ojeda Bar <n.oje.bar@gmail.com>
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

include Mirage_runtime.Configvar

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

type kval = V : 'a desc * 'a option ref -> kval

type key =
  { doc : string;
    v : kval;
    name : string }

type t = key

let name k = ocamlify k.name

let term { doc; v = V (desc, value); name } =
  Cmdliner_aux.term desc value ~doc ~name ~runtime:false

let create ?(doc = "(undocumented)") ?default name desc =
  { doc; name; v = V (desc, ref default) }

let compare k1 k2 = compare k1.name k2.name

let print_ocaml () { v = V (desc, value) } =
  match !value with
  | None -> "None"
  | Some x -> Printf.sprintf "(Some %a)" (print_ocaml desc) x

let print_meta () { v = V (desc, _) } =
  print_meta () desc
