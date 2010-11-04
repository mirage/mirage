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
  open Htcaml_parser

  let debug = ref false

  let debug (fmt: ('a , unit, string, unit) format4) =
    if !debug then
      Printf.kprintf (fun s -> Printf.eprintf "%s %!" (String.escaped s)) fmt
    else
      Printf.kprintf (fun s -> ()) fmt
        
  let update lexbuf =
    Htcaml_location.shift (String.length (Lexing.lexeme lexbuf))

  let newline lexbuf =
    Htcaml_location.newline ()
}

let all = [^ ' ' '\t' '\r' '\n' '<' '>' '/' '=' '$' '"' '\'' '^']

(* very very simple HTML lexer *)
rule token = parse
  | [' ' '\t']* { update lexbuf; token lexbuf }
  | '\n'        { newline lexbuf; token lexbuf }
  | "</>"       { debug "</>"; update lexbuf; CLOSETAG }
  | '<'         { debug "<"; update lexbuf; OPEN  }
  | '>'         { debug ">"; CLOSE }
  | '/'         { debug "/"; update lexbuf; SLASH }
  | '='         { debug "="; update lexbuf; EQ }
  | '$'         { debug "$*$"; update lexbuf; DOLLAR (dollar lexbuf) }
  | '^'         { debug "^"; update lexbuf; HAT }
  | '"'         { debug "\"*\""; update lexbuf; STRING (Printf.sprintf "\"%s\"" (dquote lexbuf)) }
  | '\''        { debug "\'"; update lexbuf; STRING (Printf.sprintf "\"%s\"" (quote lexbuf)) }
  | eof         { debug "EOF"; update lexbuf; EOF }
  | all*  as x  { debug "%s" x; update lexbuf; STRING x }

and dollar = parse
  | ([^ '$']* as str) '$' { update lexbuf; str }
 
and dquote = parse
  | ([^ '"']* as str) '"' { update lexbuf; str }
 
and quote = parse
  | ([^ '\'']* as str) '\'' { update lexbuf; str }


