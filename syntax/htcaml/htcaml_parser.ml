type token =
  | OPEN
  | CLOSE
  | SLASH
  | EQ
  | HAT
  | EOF
  | CLOSETAG
  | DOLLAR of (string)
  | STRING of (string)

open Parsing;;
# 18 "htcaml_parser.mly"
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
# 31 "htcaml_parser.ml"
let yytransl_const = [|
  257 (* OPEN *);
  258 (* CLOSE *);
  259 (* SLASH *);
  260 (* EQ *);
  261 (* HAT *);
    0 (* EOF *);
  262 (* CLOSETAG *);
    0|]

let yytransl_block = [|
  263 (* DOLLAR *);
  264 (* STRING *);
    0|]

let yylhs = "\255\255\
\002\000\002\000\002\000\003\000\003\000\004\000\004\000\005\000\
\005\000\006\000\006\000\006\000\006\000\006\000\006\000\007\000\
\007\000\001\000\000\000"

let yylen = "\002\000\
\001\000\001\000\001\000\001\000\001\000\003\000\001\000\002\000\
\001\000\005\000\006\000\004\000\005\000\003\000\001\000\002\000\
\001\000\002\000\002\000"

let yydefred = "\000\000\
\000\000\000\000\000\000\003\000\000\000\001\000\002\000\019\000\
\015\000\000\000\000\000\000\000\004\000\005\000\000\000\000\000\
\000\000\016\000\018\000\000\000\000\000\000\000\000\000\008\000\
\014\000\000\000\012\000\000\000\000\000\006\000\010\000\000\000\
\013\000\011\000"

let yydgoto = "\002\000\
\008\000\009\000\015\000\016\000\017\000\010\000\011\000"

let yysindex = "\003\000\
\001\255\000\000\005\255\000\000\014\255\000\000\000\000\000\000\
\000\000\001\255\015\000\017\255\000\000\000\000\019\255\014\255\
\023\255\000\000\000\000\001\255\030\255\028\255\014\255\000\000\
\000\000\027\255\000\000\001\255\032\255\000\000\000\000\029\255\
\000\000\000\000"

let yyrindex = "\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\001\000\000\000\000\000\000\000\000\000\009\255\024\255\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000"

let yygindex = "\000\000\
\000\000\000\000\013\000\000\000\247\255\000\000\246\255"

let yytablesize = 263
let yytable = "\018\000\
\017\000\003\000\022\000\001\000\004\000\005\000\024\000\006\000\
\007\000\026\000\007\000\007\000\012\000\007\000\019\000\007\000\
\007\000\032\000\020\000\021\000\013\000\014\000\023\000\013\000\
\014\000\009\000\009\000\025\000\009\000\028\000\029\000\027\000\
\031\000\033\000\034\000\030\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\017\000"

let yycheck = "\010\000\
\000\000\001\001\012\000\001\000\004\001\005\001\016\000\007\001\
\008\001\020\000\002\001\003\001\008\001\005\001\000\000\007\001\
\008\001\028\000\002\001\003\001\007\001\008\001\004\001\007\001\
\008\001\002\001\003\001\005\001\005\001\002\001\003\001\002\001\
\006\001\002\001\006\001\023\000\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\006\001"

let yynames_const = "\
  OPEN\000\
  CLOSE\000\
  SLASH\000\
  EQ\000\
  HAT\000\
  EOF\000\
  CLOSETAG\000\
  "

let yynames_block = "\
  DOLLAR\000\
  STRING\000\
  "

let yyact = [|
  (fun _ -> failwith "parser")
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 53 "htcaml_parser.mly"
            ( debug "DOLLAR(%s)" _1; Ant (Htcaml_location.get (), _1) )
# 177 "htcaml_parser.ml"
               : 'elt))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 54 "htcaml_parser.mly"
            ( debug "STRING(%s)" _1; String _1 )
# 184 "htcaml_parser.ml"
               : 'elt))
; (fun __caml_parser_env ->
    Obj.repr(
# 55 "htcaml_parser.mly"
            ( debug "EQ"; String "=" )
# 190 "htcaml_parser.ml"
               : 'elt))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 59 "htcaml_parser.mly"
            ( debug "nDOLLAR(%s)" _1; Ant (Htcaml_location.get (), _1) )
# 197 "htcaml_parser.ml"
               : 'name))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 60 "htcaml_parser.mly"
            ( debug "nSTRING(%s)" _1; String _1 )
# 204 "htcaml_parser.ml"
               : 'name))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'name) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'name) in
    Obj.repr(
# 64 "htcaml_parser.mly"
                  ( debug "PROP"; Prop (_1, _3) )
# 212 "htcaml_parser.ml"
               : 'attr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'name) in
    Obj.repr(
# 65 "htcaml_parser.mly"
                  ( debug "NAME"; _1 )
# 219 "htcaml_parser.ml"
               : 'attr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'attr) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'attrs) in
    Obj.repr(
# 69 "htcaml_parser.mly"
                ( debug "ATTR-SEQ"; Seq (_1, _2) )
# 227 "htcaml_parser.ml"
               : 'attrs))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'attr) in
    Obj.repr(
# 70 "htcaml_parser.mly"
                ( debug "ATTR"; _1 )
# 234 "htcaml_parser.ml"
               : 'attrs))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 3 : string) in
    let _4 = (Parsing.peek_val __caml_parser_env 1 : 'all) in
    Obj.repr(
# 75 "htcaml_parser.mly"
       ( debug "<%s>...</>" _2; Tag (_2, Nil, _4) )
# 242 "htcaml_parser.ml"
               : 'one))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 4 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 3 : 'attrs) in
    let _5 = (Parsing.peek_val __caml_parser_env 1 : 'all) in
    Obj.repr(
# 77 "htcaml_parser.mly"
       ( debug "<%s ...>...</>" _2; Tag (_2, _3, _5) )
# 251 "htcaml_parser.ml"
               : 'one))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : string) in
    Obj.repr(
# 79 "htcaml_parser.mly"
       ( debug "<%s/>" _2; Tag (_2, Nil, Nil) )
# 258 "htcaml_parser.ml"
               : 'one))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 3 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 2 : 'attrs) in
    Obj.repr(
# 81 "htcaml_parser.mly"
       ( debug "<%s .../>" _2; Tag (_2, _3, Nil) )
# 266 "htcaml_parser.ml"
               : 'one))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 1 : 'attrs) in
    Obj.repr(
# 83 "htcaml_parser.mly"
       ( debug "HAT"; _2 )
# 273 "htcaml_parser.ml"
               : 'one))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'elt) in
    Obj.repr(
# 85 "htcaml_parser.mly"
       ( debug "ELT"; _1 )
# 280 "htcaml_parser.ml"
               : 'one))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'one) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'all) in
    Obj.repr(
# 89 "htcaml_parser.mly"
             ( Seq(_1, _2) )
# 288 "htcaml_parser.ml"
               : 'all))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'one) in
    Obj.repr(
# 90 "htcaml_parser.mly"
         ( _1 )
# 295 "htcaml_parser.ml"
               : 'all))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'all) in
    Obj.repr(
# 94 "htcaml_parser.mly"
             ( debug "MAIN"; newline (); _1 )
# 302 "htcaml_parser.ml"
               : Htcaml_ast.t))
(* Entry main *)
; (fun __caml_parser_env -> raise (Parsing.YYexit (Parsing.peek_val __caml_parser_env 0)))
|]
let yytables =
  { Parsing.actions=yyact;
    Parsing.transl_const=yytransl_const;
    Parsing.transl_block=yytransl_block;
    Parsing.lhs=yylhs;
    Parsing.len=yylen;
    Parsing.defred=yydefred;
    Parsing.dgoto=yydgoto;
    Parsing.sindex=yysindex;
    Parsing.rindex=yyrindex;
    Parsing.gindex=yygindex;
    Parsing.tablesize=yytablesize;
    Parsing.table=yytable;
    Parsing.check=yycheck;
    Parsing.error_function=parse_error;
    Parsing.names_const=yynames_const;
    Parsing.names_block=yynames_block }
let main (lexfun : Lexing.lexbuf -> token) (lexbuf : Lexing.lexbuf) =
   (Parsing.yyparse yytables 1 lexfun lexbuf : Htcaml_ast.t)
