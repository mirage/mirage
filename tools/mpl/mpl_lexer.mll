(*
 * Copyright (c) 2005 Anil Madhavapeddy <anil@recoil.org>
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
 *
 * $Id: mpl_lexer.mll,v 1.12 2005/11/29 20:51:50 avsm Exp $
 *)

{
open Mpl_location
open Mpl_parser
exception Eof
}

let decimal_literal = ['0'-'9'] ['0'-'9' '_']*
let hex_literal =
  '0' ['x' 'X'] ['0'-'9' 'A'-'F' 'a'-'f']['0'-'9' 'A'-'F' 'a'-'f' '_']*
let oct_literal =
  '0' ['o' 'O'] ['0'-'7'] ['0'-'7' '_']*
let bin_literal =
  '0' ['b' 'B'] ['0'-'1'] ['0'-'1' '_']*
let int_literal =
  decimal_literal | hex_literal | oct_literal | bin_literal
let lowercase = ['a'-'z' '\223'-'\246' '\248'-'\255' '_']
let uppercase = ['A'-'Z' '\192'-'\214' '\216'-'\222']
let identchar = 
  ['A'-'Z' 'a'-'z' '_' '\192'-'\214' '\216'-'\246' '\248'-'\255' '\'' '0'-'9']

rule token = parse
| [ ' ' '\t' ] { token lexbuf }
| [ '\n' ] { new_line lexbuf; token lexbuf }
| '{'   { LBRACE(next_token lexbuf) }
| '}'   { RBRACE(next_token lexbuf) }
| '('   { LBRACKET(next_token lexbuf) }
| ')'   { RBRACKET(next_token lexbuf) }
| '['   { SLBRACKET(next_token lexbuf) }
| ']'   { SRBRACKET(next_token lexbuf) }
| ':'   { COLON(next_token lexbuf) }
| ';'   { SEMICOLON(next_token lexbuf) }
| ','   { COMMA(next_token lexbuf) }
| '|'  { PIPE(next_token lexbuf) }
| "->" { PATTERN_BIND(next_token lexbuf) }
| "=>" { DEFAULT_PATTERN_BIND(next_token lexbuf) }
| "&&" { AND(next_token lexbuf) }
| "||" { OR(next_token lexbuf) }
| "!" { NOT(next_token lexbuf) }
| "+" { PLUS(next_token lexbuf) }
| "-" { MINUS(next_token lexbuf) }
| "*" { MULTIPLY(next_token lexbuf) }
| "/" { DIVIDE(next_token lexbuf) }
| ">" { GREATER(next_token lexbuf) }
| ">=" { GREATER_EQUAL(next_token lexbuf) }
| "<" { LESS(next_token lexbuf) }
| "<=" { LESS_EQUAL(next_token lexbuf) }
| "==" { EQUALS(next_token lexbuf) }
| ".." { RANGE(next_token lexbuf) }
| "variant" { VARIANT(next_token lexbuf) }
| "packet" { PACKET(next_token lexbuf) }
| "classify" { CLASSIFY(next_token lexbuf) }
| "array" { ARRAY(next_token lexbuf) }
| "true" { TRUE(next_token lexbuf) }
| "false" { FALSE(next_token lexbuf) }
| "when" { WHEN(next_token lexbuf) }
| "struct" { STRUCT(next_token lexbuf) }
| "typedef" { TYPEDEF(next_token lexbuf) }
| "\"" { string_e (Buffer.create 128) lexbuf }
| uppercase identchar* { UIDENTIFIER(Lexing.lexeme lexbuf, next_token lexbuf) }
| lowercase identchar* { IDENTIFIER(Lexing.lexeme lexbuf, next_token lexbuf) }
| int_literal { INT(int_of_string (Lexing.lexeme lexbuf), next_token lexbuf) }
| "/*" { ignore(comment lexbuf); token lexbuf }
| "//" { ignore(lexbuf); token lexbuf }
| eof { EOF(next_token lexbuf) }
| _ { raise (Mpl_syntaxtree.Syntax_error  (!Mpl_location.current_location)) }
and comment = parse
| "/*" { ignore(comment lexbuf); comment lexbuf }
| "*/" { true }
| '\n' { ignore(new_line lexbuf); comment lexbuf }
| _ { comment lexbuf }

and single_comment = parse
| '\n' { new_line lexbuf; true }
| _ { single_comment lexbuf }

and string_e s = parse
| '\"' { STRING(Buffer.contents s, next_token lexbuf) }
(* XXX add support for string escapes here *)
| _ as x { Buffer.add_char s x; string_e s lexbuf }
