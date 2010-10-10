(*
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.com>
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

open Camlp4.PreCast
open Htcaml_ast

module Gram = MakeGram(Lexer)

let htcaml_eoi = Gram.Entry.mk "htcaml_eoi"

let parse_htcaml_eoi loc s = Gram.parse_string htcaml_eoi loc s

let debug = ref false

let debug (fmt: ('a , unit, string, unit) format4) =
  if !debug then
    Printf.kprintf (fun s -> Printf.eprintf "%s%!" s) fmt
  else
    Printf.kprintf (fun s -> ()) fmt

EXTEND Gram
  GLOBAL: htcaml_eoi;

  str: [[
      s = LIDENT    -> debug "LIDENT(%s) " s; s
    | s = UIDENT    -> debug "UIDENT(%s) " s; s
    | "-"; s = SELF -> debug "-(%s) " s; "-" ^ s
    | "#"; s = SELF -> debug "#(%s) " s; "#" ^ s
    | "#"; s = SELF -> debug "#(%s) " s; "#" ^ s
    | "."; s = SELF -> debug ".(%s) " s; "." ^ s
    | "."           -> debug ". "; "."
    | s1 = SELF; "-"; s2 = SELF -> debug "(%s-%s) " s1 s2; s1 ^ s2
    | s = STRING    -> debug "STRING(%S) " s; s
    | i = INT       -> debug "INT(%s) " i; i
    | f = FLOAT     -> debug "FLOAT(%s) " f; f
    | s = SYMBOL    -> debug "SYMBOL(%s) " s; s
 ]];

  alist0: [[
     s1 = str; "="; s2 = str ->
       debug "EQ(%s,%s) " s1 s2;
       Prop(String s1, String s2)
   | s1 = str; "="; a2 = anti ->
       debug "EQ(%s,--) " s1;
       Prop(String s1, a2)
   | a1 = anti; "="; s2 = str ->
       debug "EQ(--,%s) " s2;
       Prop(a1, String s2)
   | a1 = anti; "="; a2 = anti ->
       debug "EQ(--,--) ";
       Prop(a1, a2)
   | a = anti ->
       debug "----  ";
       a
  ]];
  
  alist: [[
      hd = alist0            -> hd
    | hd = alist0; tl = SELF -> debug "ASEQ "; Seq(hd, tl)
  ]];

  anti: [[
   `ANTIQUOT (""|"int"|"flo"|"str"|"list"|"alist" as n, s) ->
     debug "ANTI(%s:%s) " n s;
     Ant (_loc, n ^ ":" ^ s)
  ]];

  htcaml0: [[
       s = str           -> String s

    | "</"; s = str; ">"            -> debug "EMPTY-TAG(%s) " s; Tag(s, Nil, Nil)
    | "</"; s = str; l = alist; ">" -> debug "EMPTY-TAG2(%s) " s; Tag(s, l, Nil)

    | "<"; s = str; ">"; e = htcaml; "</>" ->
        debug "TAG(%s) " s;
        Tag (s, Nil, e)
    | "<"; s = str; l = alist; ">"; e = htcaml; "</>" ->
        debug "TAG2(%s) " s;
        Tag (s, l, e)

    | a = anti  -> a
    | a = alist -> a
    | s1=SELF;"=";s2=SELF -> Prop(s1, s2) (* XXX: very annoying that we need that one *)
  ]];

  htcaml: [[
	  hd = htcaml0             -> hd
    | hd = htcaml0 ; tl = SELF -> debug "SEQ "; Seq (hd, tl)
    | -> Nil
  ]];

  htcaml_eoi: [[ x = htcaml; EOI -> debug "\n"; x ]];
END
