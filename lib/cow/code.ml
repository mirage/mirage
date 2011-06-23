(*
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
 *)

let regexp lowercase = ['a'-'z' '\223'-'\246' '\248'-'\255' '_']
let regexp uppercase = ['A'-'Z' '\192'-'\214' '\216'-'\222']
let regexp identchar = ['A'-'Z' 'a'-'z' '_' '\192'-'\214' '\216'-'\246' '\248'-'\255' '\'' '0'-'9' ]
let regexp ident = (lowercase|uppercase) identchar*

let regexp blank = [' ' '\n' '\t']
let regexp not_blank = [^ ' ' '\n' '\t']

let regexp keywords1 =
    "do"
  | "done"
  | "downto"
  | "else"
  | "for"
  | "if"
  | "lazy"
  | "match"
  | "new"
  | "then"
  | "to"
  | "try"
  | "when"
  | "while"
  | "with"
  | "as"
  | "assert"
  | "exception"
  | "fun"
  | "function"
  | "mutable"
  | "private"
  | "raise"
  | "<:" identchar+ "<"
  | ">>"

let regexp keywords2 =
    "|"
  | "||"
  | "&"
  | "&&"
  | "or"
  | "of"
  | "asr"
  | "land"
  | "lor"
  | "lsl"
  | "lsr"
  | "lxor"
  | "mod"
  | "["
  | "]"
  | "[|"
  | "|]"
  | ";"
  | "="
  | "("
  | ")"
  | ">"
  | "<"
  | "!"
  | "*"
  | "+"
  | "^"
  | "@"
  | ":"
  | "$"
  | "{"
  | "}"

let regexp keywords3 =
    "string"
  | "int"
  | "float"
  | "array"
  | "list"

let regexp keywords4 =
    "and"
  | "class"
  | "constraint"
  | "include"
  | "external"
  | "functor"
  | "in"
  | "inherit"
  | "initializer"
  | "let"
  | "method"
  | "module"
  | "rec"
  | "type"
  | "val"
  | "virtual"
  | "open"
  | "begin"
  | "end"
  | "object"
  | "sig"
  | "struct"

let regexp keywords5 =
    "false"
  | "true"

let regexp keywords6 =
  uppercase identchar* '.'

let regexp keywords7 =
    '"'    ("\\\"" | [^ '"']   )* '"'
  | '#' identchar+

let regexp keywords8 =
        ['0' - '9']+
  | '-' ['0' - '9']+

let html_of_keyword i str =
  let k = "keyword" ^ string_of_int i in
  <:xml<<span class=$str:k$>$str:str$</span>&>>

let html_of_comments str =
  <:xml<<span class="comments">$str:str$</span>&>>

let ocaml str : Html.t =

  let rec main accu = lexer
  | "(*"               ->
    main (html_of_comments (comments ["(*"] lexbuf) @ accu) lexbuf

  | keywords8 ->
    let str = Ulexing.utf8_lexeme lexbuf in
    main (html_of_keyword 8 str @ accu) lexbuf

  | keywords7 ->
    let str = Ulexing.utf8_lexeme lexbuf in
    main (html_of_keyword 7 str @ accu) lexbuf

  | keywords6 ->
    let str = Ulexing.utf8_lexeme lexbuf in
    main (html_of_keyword 6 str @ accu) lexbuf

  | keywords5 ->
    let str = Ulexing.utf8_lexeme lexbuf in
    main (html_of_keyword 5 str @ accu) lexbuf

  | keywords4 ->
    let str = Ulexing.utf8_lexeme lexbuf in
    main (html_of_keyword 4 str @ accu) lexbuf

  | keywords3 ->
    let str = Ulexing.utf8_lexeme lexbuf in
    main (html_of_keyword 3 str @ accu) lexbuf

  | keywords2 ->
    let str = Ulexing.utf8_lexeme lexbuf in
    main (html_of_keyword 2 str @ accu) lexbuf

  | keywords1 ->
    let str = Ulexing.utf8_lexeme lexbuf in
    main (html_of_keyword 1 str @ accu) lexbuf

  | ident | blank+ | _ ->
    let str = Ulexing.utf8_lexeme lexbuf in
    main (`Data str :: accu) lexbuf

  | eof               ->
    List.rev accu
      
  and comments accu = lexer
      | "*)" ->
        String.concat "" (List.rev ("*)" :: accu))

      | "(*" ->
        comments (comments ["(*"] lexbuf :: accu) lexbuf

      | _    ->
        let str = Ulexing.utf8_lexeme lexbuf in
        comments (str :: accu) lexbuf in

  <:html<<div class="ocaml"><pre><code>$main [] (Ulexing.from_utf8_string str)$</code></pre></div>&>>

let ocaml_css = <:css<
  .ocaml {
    code      { font-family: monospace; }
    .keyword1 { display: inline; color: #15317E; }
    .keyword2 { display: inline; color: #7D2252; }
    .keyword3 { display: inline; color: #C48189; }
    .keyword4 { display: inline; color: #F88017; }
    .keyword5 { display: inline; color: #4E9258; }
    .keyword6 { display: inline; color: #347C17; }
    .keyword7 { display: inline; color: #8BB381; }
    .keyword8 { display: inline; color: #EE9A4D; }
    .comments { display: inline; color: #990000; }
  }
>>
