/*
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
 * $Id: mpl_parser.mly,v 1.15 2005/12/05 00:46:06 avsm Exp $
 */

%{
    open Mpl_location
    open Mpl_syntaxtree
    open Printf

    let parse_error msg =
        raise (Syntax_error !Mpl_location.current_location)
        
    let id (x,_) = x
    let loc (_,x) = x

    let tdefs = Hashtbl.create 1
    let sdefs = Hashtbl.create 1
%}

%token <Mpl_location.t> EOL EOF
%token <string * Mpl_location.t> IDENTIFIER STRING UIDENTIFIER
%token <int * Mpl_location.t> INT
%token <Mpl_location.t> STRUCT TYPEDEF DEFAULT_PATTERN_BIND
%token <Mpl_location.t> PACKET VARIANT CLASSIFY ARRAY RANGE
%token <Mpl_location.t> LBRACKET RBRACKET LBRACE RBRACE SLBRACKET SRBRACKET
%token <Mpl_location.t> COLON SEMICOLON COMMA PIPE PATTERN_BIND WHEN
%token <Mpl_location.t> PLUS COMMA MINUS MULTIPLY DIVIDE GREATER GREATER_EQUAL
%token <Mpl_location.t> LESS LESS_EQUAL EQUALS UMINUS TRUE FALSE AND OR NOT

/* XXX - review these associativities - avsm */
%left RANGE
%left OR
%left AND
%right NOT
%left GREATER GREATER_EQUAL LESS LESS_EQUAL EQUALS
%left PLUS MINUS
%left MULTIPLY DIVIDE
%nonassoc UMINUS

%start main
%type <Mpl_syntaxtree.packets> main
%%
main:
  st_defs packet_list EOF {
	{pdefs=$2; tdefs=tdefs; sdefs=sdefs}
  }
;
st_def:
| TYPEDEF IDENTIFIER IDENTIFIER SEMICOLON { Hashtbl.add tdefs (id $2) ((loc $2), (id $3)); }
| STRUCT LBRACE statements RBRACE IDENTIFIER SEMICOLON { Hashtbl.add sdefs (id $5) $3; }
;
st_defs:
| st_def st_defs { () }
| { () }
;
packet_list:
| packet_decl packet_list {$1::$2}
| packet_decl {[$1]}
;
packet_decl:
| PACKET IDENTIFIER LBRACKET packet_args RBRACKET packet_body
    {{Mpl_syntaxtree.name=id $2; args=$4; body=$6; loc=$1}}
| PACKET IDENTIFIER packet_body
    {{Mpl_syntaxtree.name=id $2; args=[]; body=$3; loc=$1}}
;
packet_args:
| packet_arg COMMA packet_args { $1::$3 }
| packet_arg { [$1] }
;
packet_arg:
| IDENTIFIER IDENTIFIER {
    match Mpl_syntaxtree.packet_var_of_string (id $2) (id $1) with
    |Some x -> x
    |None -> parse_error "Unknown variable type"
  }
;
packet_body:
| LBRACE statements RBRACE { $2 }
;
statements:
| statement statements { $1::$2 }
| statement { [$1] }
;
packet_call_args:
| IDENTIFIER COMMA packet_call_args { id $1 :: $3 }
| IDENTIFIER { [id $1] }
| { [] }
;
statement:
| IDENTIFIER COLON PACKET IDENTIFIER LBRACKET packet_call_args RBRACKET SEMICOLON
    {
	   (loc $1, (Mpl_syntaxtree.Packet (id $1, id $4, $6)))
	 }
| IDENTIFIER COLON IDENTIFIER opt_var_size opt_var_attrs SEMICOLON 
    {
      (loc $1, (Mpl_syntaxtree.Variable (id $1, id $3, $4, $5)))
    }
| CLASSIFY LBRACKET IDENTIFIER RBRACKET LBRACE classify_matches RBRACE SEMICOLON
    {
      ($1, (Mpl_syntaxtree.Classify (id $3, $6)))
    }
| IDENTIFIER COLON ARRAY LBRACKET expr RBRACKET LBRACE statements RBRACE SEMICOLON
    {
      (loc $1, (Mpl_syntaxtree.Array (id $1, $5, $8)))
    }
| LBRACKET RBRACKET SEMICOLON { ($1, Mpl_syntaxtree.Unit) }
;
classify_matches:
| classify_match classify_matches { $1::$2 }
| classify_match { [$1] }
;
classify_match:
|PIPE expr COLON expr classify_opt_when PATTERN_BIND statements
    {($2, $4, $5, $7)}
;
classify_opt_when:
|WHEN LBRACKET expr RBRACKET { Some $3 }
| { None }
;
opt_var_attrs:
| var_attr opt_var_attrs { $1::$2 }
| {[]} 
;
var_attr:
| VARIANT LBRACE variant_matches RBRACE {
	let def = ref None in
	let l = List.map (function |`Normal x -> x
		|`Default x -> (if !def = None then def := Some (id x)
			else parse_error "only one variant default allowed"); x) $3 in
	Mpl_syntaxtree.Variant (l,(!def))
  }
| IDENTIFIER LBRACKET expr RBRACKET {
        match Mpl_syntaxtree.attr_of_string $3 (id $1) with
        |Some x -> x
        |None -> parse_error "unknown identifier"
    }
;
variant_matches:
| variant_match variant_matches { $1::$2 }
| variant_match { [$1] }
;
variant_match:
| PIPE expr PATTERN_BIND UIDENTIFIER {`Normal ($2, id $4) }
| PIPE expr DEFAULT_PATTERN_BIND UIDENTIFIER {`Default ($2, id $4) }
;
opt_var_size:
| SLBRACKET expr SRBRACKET { Some $2 }
| { None }
;
expr:
| INT { Mpl_syntaxtree.Int_constant (id $1) }
| IDENTIFIER {Mpl_syntaxtree.Identifier (id $1)}
| LBRACKET expr RBRACKET { $2 }
| expr PLUS expr { Mpl_syntaxtree.Plus ($1, $3) }
| expr MINUS expr { Mpl_syntaxtree.Minus ($1, $3) }
| expr MULTIPLY expr { Mpl_syntaxtree.Multiply ($1, $3) }
| expr DIVIDE expr { Mpl_syntaxtree.Divide ($1, $3) }
| MINUS expr %prec UMINUS {
    Mpl_syntaxtree.Multiply ( Mpl_syntaxtree.Int_constant (-1), $2) }
| TRUE {Mpl_syntaxtree.True}
| FALSE {Mpl_syntaxtree.False}
| expr AND expr {Mpl_syntaxtree.And ($1,$3)}
| expr OR expr {Mpl_syntaxtree.Or ($1,$3)}
| NOT expr {Mpl_syntaxtree.Not $2}
| expr GREATER expr {Mpl_syntaxtree.Greater ($1, $3)}
| expr GREATER_EQUAL expr {Mpl_syntaxtree.Greater_or_equal ($1, $3)}
| expr LESS expr {Mpl_syntaxtree.Less ($1, $3)}
| expr LESS_EQUAL expr {Mpl_syntaxtree.Less_or_equal ($1, $3)}
| expr EQUALS expr {Mpl_syntaxtree.Equals ($1, $3)}
| expr RANGE expr {Mpl_syntaxtree.Range ($1,$3)}
| IDENTIFIER LBRACKET opt_expr_arg RBRACKET { Mpl_syntaxtree.Function_call (id $1, $3) }
| STRING { Mpl_syntaxtree.String_constant (id $1) }
;
opt_expr_arg:
| IDENTIFIER { Some (id $1) }
| { None }
;