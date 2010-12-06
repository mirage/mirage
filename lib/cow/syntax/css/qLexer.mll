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

{
  open Parser

  let debug = ref false

  let debug (fmt: ('a , unit, string, unit) format4) =
    if !debug then
      Printf.kprintf (fun s -> Printf.eprintf "%s %!" (String.escaped s)) fmt
    else
      Printf.kprintf (fun s -> ()) fmt
        
  let update lexbuf =
    Location.shift (String.length (Lexing.lexeme lexbuf))

  let newline lexbuf =
    Location.newline ()
}

let all = [^ ' ' '\t' '\r' '\n' '{' '}' '(' ')' ';' ',' '$' '"' '\'' '=']

(* very very simple HTML lexer *)
rule token = parse
  | [' ' '\t' '\r']* { update lexbuf; token lexbuf }
  | '\n'             { newline lexbuf; token lexbuf }
  | '{'              { debug "{"; update lexbuf; OPEN  }
  | '}'              { debug "}"; CLOSE }
  | '('              { debug "("; LEFT }
  | ')'              { debug ")"; RIGHT }
  | ','              { debug ","; update lexbuf; COMMA }
  | ';'              { debug ";"; update lexbuf; SEMI }
  | '$'              { debug "$*$"; update lexbuf; DOLLAR (dollar lexbuf) }
  | '"'              { debug "\"*\""; update lexbuf; STRING (Printf.sprintf "\"%s\"" (dquote lexbuf)) }
  | '\''             { debug "\'"; update lexbuf; STRING (Printf.sprintf "\"%s\"" (quote lexbuf)) }
  | '='              { debug "="; EQ }
  | "/*"             { comments lexbuf; token lexbuf }
  | eof              { debug "EOF"; update lexbuf; EOF }
  | all*  as x       { update lexbuf;
                       if x.[String.length x - 1] = ':' then
                         (debug "P%s" x; PROP (String.sub x 0 (String.length x - 1)))
                       else
                         (debug "%s" x; STRING x) }

and dollar = parse
  | ([^ '$']* as str) '$' { update lexbuf; str }
 
and dquote = parse
  | ([^ '"']* as str) '"' { update lexbuf; str }
 
and quote = parse
  | ([^ '\'']* as str) '\'' { update lexbuf; str }

and comments = parse
  | "*/" { () }
  | _    { comments lexbuf }
