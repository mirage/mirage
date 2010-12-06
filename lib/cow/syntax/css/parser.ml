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

open Qast

let debug = ref false

let set_debug x =
  debug := x

let ef (fmt: ('a , unit, string, unit) format4) =
    if !debug then
      Printf.kprintf (fun s -> Printf.eprintf "%s" s) fmt
    else
      Printf.kprintf (fun s -> ()) fmt

type token = 
  | STRING of (string)
  | SEMI
  | RIGHT
  | PROP of (string)
  | OPEN
  | LEFT
  | EQ
  | EOF
  | DOLLAR of (string)
  | COMMA
  | CLOSE

let parse_tree = Stack.create ()

exception Parse_error of (string Stack.t)

let pp_error pt =
  ef "[PARSE ERROR] parse tree:\n";
  Stack.iter (ef "%s ") pt;
  ef "\n"

let parse_error () =
  raise (Parse_error (Stack.copy parse_tree))

let with_rule r fn =
  try
    Stack.push r parse_tree;
    let res = fn () in
    let (_ : string) = Stack.pop parse_tree in
    res
  with e ->
    let (_ : string) = Stack.pop parse_tree in
    raise e

module Lazy_tokens = struct
    
  type ('token, 'lexbuf) t = {
    mutable buffer : 'token list;
    mutable size: int;
    mutable lexbuf : 'lexbuf;
    lexer : 'lexbuf -> 'token;
    mutable next : unit -> 'token;
  }

  let copy t =
    let lexbuf = {
      t.lexbuf with
        Lexing.lex_start_p = t.lexbuf.Lexing.lex_start_p;
        Lexing.lex_curr_p  = t.lexbuf.Lexing.lex_curr_p;
    } in {
      t with
        lexbuf = lexbuf;
        next   = fun () -> t.lexer lexbuf
    }

  let dummy buffer tokens = {
    buffer = buffer;
    size   = List.length buffer;
    lexbuf = None;
    lexer  = (fun _ -> EOF);
    next   =
      let l = ref tokens in
      fun () ->
        match !l with
          | []   -> parse_error ()
          | h::t ->
            l := t;
            h
  }

  let make lexer lexbuf = {
    buffer = [];
    size = 0;
    lexbuf = lexbuf;
    lexer = lexer;
    next = function () -> lexer lexbuf;
  }
    
  let rec pick n l =
    match n,l with
      | 0, _
      | _, []   -> []
      | n, h::t -> h :: pick (n-1) t

  let _ =
    assert (pick 3 [1;2;3;4;5;6] = [1;2;3]);
    assert (pick 3 [1;2] = [1;2])
  
  let rec throw n l =
    match n,l with
      | 0, l    -> l
      | n, []   -> []
      | n, h::t -> throw (n-1) t

  let _ =
    assert (throw 3 [1;2;3;4;5;6] = [4;5;6]);
    assert (throw 3 [1;2] = [])

  let refill n tokens =
    let l = ref [] in
    for i = 1 to n do
      try l := tokens.next () :: !l
      with Parse_error _ -> ()
    done;
    tokens.buffer <- tokens.buffer @ List.rev !l;
    tokens.size <- tokens.size + List.length !l

  let (===) x y =
    x.buffer = y &&
    x.size = List.length y

  let _ =
    let tokens = dummy [EQ;EQ] [EQ;EQ] in
    refill 1 tokens;
    assert (tokens === [EQ;EQ;EQ]);
    refill 3 tokens;
    assert (tokens === [EQ;EQ;EQ;EQ])

  let look n tokens =
    if tokens.size <= n then begin
      refill (n - tokens.size) tokens;
      tokens.size <- n;
    end;
    pick n tokens.buffer

  let _ =
    let tokens = dummy [EQ;EQ] [EQ;EQ] in
    assert (look 1 tokens = [EQ]);
    assert (look 3 tokens = [EQ;EQ;EQ]);
    assert (look 6 tokens = [EQ;EQ;EQ;EQ])

  let seek n tokens =
    if tokens.size >= n then begin
      tokens.buffer <- throw n tokens.buffer;
      tokens.size <- tokens.size - n;
    end else begin
      for i = tokens.size to n do
        let _ = tokens.next () in ()
      done;
    tokens.buffer <- [];
    tokens.size <- 0;
    end

  let _ =
    let tokens = dummy [EQ;EQ] [EQ;EQ] in
    seek 1 tokens;
    assert (tokens === [EQ]);
    seek 2 tokens;
    assert (tokens === [])

  let expect token tokens =
    if look 1 tokens = [token] then
      seek 1 tokens
    else
      parse_error ()

  let _ =
    let tokens = dummy [EQ;COMMA] [LEFT;OPEN] in
    expect EQ tokens;
    expect COMMA tokens;
    expect LEFT tokens;
    expect OPEN tokens;
    try expect EOF tokens; assert false
    with Parse_error _ -> ()

  let maybe token tokens =
    try
      expect token tokens
    with _ ->
      ()

  let _ =
    let tokens = dummy [EQ;COMMA] [LEFT;OPEN] in
    maybe OPEN tokens;
    maybe EQ tokens;
    expect COMMA tokens

  let restore ~snapshot tokens =
    tokens.buffer <- snapshot.buffer;
    tokens.size   <- snapshot.size;
    tokens.lexbuf <- snapshot.lexbuf;
    tokens.next   <- snapshot.next
end

open Lazy_tokens

let rec elt tokens =
  with_rule "elt" (fun () ->
    match look 3 tokens with
      | [STRING s1; EQ; STRING s2] ->
        ef "%s=%s " s1 s2;
        seek 3 tokens;
        ESeq (String s1, ESeq( String "=", String s2))
      | [STRING s1; EQ; DOLLAR aq] ->
        ef "%s=$%s$" s1 aq;
        seek 3 tokens;
        ESeq(String s1, ESeq(String "=", Ant (Location.get (), aq)))
      | [STRING s1; LEFT; _ ] ->
        ef "%s(" s1;
        seek 2 tokens;
        let exprs = exprs tokens in
        expect RIGHT tokens;
        ef ") << %s >>" (Printer.to_string exprs);
        Fun(String s1, exprs)
      | [STRING s; _; _ ] ->
        ef "%s " s;
        seek 1 tokens;
        String s
      | [DOLLAR aq; _; _  ] ->
        ef "$%s$ " aq;
        seek 1 tokens;
        Ant (Location.get (), aq)
      | _ ->
        ef "--\n";
        parse_error ())

and expr tokens =
  with_rule "expr" (fun () ->
    let elt = elt tokens in
    let snapshot = copy tokens in
    try
      let expr = expr tokens in
      ESeq (elt, expr)
    with Parse_error _ ->
      restore ~snapshot tokens;
      elt)

and exprs tokens =
  with_rule "exprs" (fun () ->
    ef "      EXPRS: ";
    let expr = expr tokens in
    match look 1 tokens with
      | [COMMA] ->
        ef "        COMMA\n";
        seek 1 tokens;
        let exprs = exprs tokens in
        Comma (expr, exprs)
      | _ ->
        expr)

and prop tokens =
  with_rule "prop" (fun () ->
    match look 2 tokens with
      | [PROP p; _ ] ->
        ef "    PROP: %s\n" p;
        seek 1 tokens;
        let exprs = exprs tokens in
        expect SEMI tokens;
        Rule (String p, exprs)
      | _ ->
        let snapshot = copy tokens in
        try
          let exprs = exprs tokens in
          expect OPEN tokens;
          ef "    (\n";
          let props = props tokens in
          expect CLOSE tokens;
          ef "    )\n";
          maybe SEMI tokens;
          Decl(exprs, props)
        with e ->
          restore ~snapshot tokens;
          match look 1 tokens with
            | [DOLLAR aq] ->
              ef "      DOLLAR: %s\n" aq;
              seek 1 tokens;
              maybe SEMI tokens;
              Ant (Location.get (), aq)
            | _ -> raise e)

and props tokens =
  with_rule "props" (fun () ->
    let prop = prop tokens in
    let snapshot = copy tokens in
    try
      let props = props tokens in
      RSeq(prop, props)
    with Parse_error _ ->
      restore ~snapshot tokens;
      prop)

and all tokens =
  with_rule "all" (fun () ->
    let snapshot = copy tokens in
    try
      ef "  Trying PROP branch:\n";
      let res = props tokens in
      ef "  PROP: success!\n";
      res
    with Parse_error _ ->
      ef "  PROP: failed!\n  Trying EXPR instead:\n";
      restore ~snapshot tokens;
      let res = exprs tokens in
      ef "  EXPR: success!\n";
      res
)

and main tokens =
  with_rule "main" (fun () ->
    ef "MAIN\n";
    let all = all tokens in
    ef "NI";
    expect EOF tokens;
    ef "AM\n";
    all)

let main lexer lexbuf =
  let tokens = make lexer lexbuf in
  try
    main tokens
  with Parse_error pt ->
    pp_error pt;
    Camlp4.PreCast.Loc.raise (Location.get ()) Parsing.Parse_error
