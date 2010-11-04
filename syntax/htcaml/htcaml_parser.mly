/*
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.org>
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
 */

%{
  open Htcaml_ast

  let debug = ref false

  let parse_error str =
    Camlp4.PreCast.Loc.raise (Htcaml_location.get ()) Parse_error

  let newline () =
    if !debug then
      Printf.eprintf "\n"

  let debug (fmt: ('a , unit, string, unit) format4) =
    if !debug then
      Printf.kprintf (fun s -> Printf.eprintf "[%s] %!" (String.escaped s)) fmt
    else
      Printf.kprintf (fun s -> ()) fmt
%}

%token OPEN CLOSE SLASH EQ HAT EOF CLOSETAG
%token <string> DOLLAR STRING

%left OPEN
%left CLOSE
%left SLASH
%left EQ
%left HAT
%left DOLLAR
%left STRING

%start main
%type <Htcaml_ast.t> main

%%

 elt:
   | DOLLAR { debug "DOLLAR(%s)" $1; Ant (Htcaml_location.get (), $1) }
   | STRING { debug "STRING(%s)" $1; String $1 }
   | EQ     { debug "EQ"; String "=" }
 ;

 name:
   | DOLLAR { debug "nDOLLAR(%s)" $1; Ant (Htcaml_location.get (), $1) }
   | STRING { debug "nSTRING(%s)" $1; String $1 }
 ;

 attr:
   | name EQ name { debug "PROP"; Prop ($1, $3) }
   | name         { debug "NAME"; $1 }
 ;

 attrs:
   | attr attrs { debug "ATTR-SEQ"; Seq ($1, $2) }
   | attr       { debug "ATTR"; $1 }
 ;

 one:
   | OPEN STRING CLOSE all CLOSETAG
       { debug "<%s>...</>" $2; Tag ($2, Nil, $4) }
   | OPEN STRING attrs CLOSE all CLOSETAG
       { debug "<%s ...>...</>" $2; Tag ($2, $3, $5) }
   | OPEN STRING SLASH CLOSE
       { debug "<%s/>" $2; Tag ($2, Nil, Nil) }
   | OPEN STRING attrs SLASH CLOSE
       { debug "<%s .../>" $2; Tag ($2, $3, Nil) }
   | HAT attrs HAT
       { debug "HAT"; $2 }
   | elt
       { debug "ELT"; $1 }
 ;

all:
   | one all { Seq($1, $2) }
   | one { $1 }
;

main:
   | all EOF { debug "MAIN"; newline (); $1 }
