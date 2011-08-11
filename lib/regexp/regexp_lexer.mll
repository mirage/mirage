


{

  open Regular_expr;;
  open Regexp_parser;;
  open Lexing;;

  let add_inter a b l =
    let rec add_rec a b l =
      match l with
    | [] -> [(a,b)]
    | (a1,b1)::r ->
        if b < a1
        then (a,b)::l
        else
          if b1 < a
          then (a1,b1)::(add_rec a b r)
          else
        (* intervals [a,b] and [a1,b1] intersect *)
        add_rec (min a a1) (max b b1) r
    in
    if a>b then l else add_rec a b l

  let complement l =
    let rec comp_rec a l =
      match l with
    | [] ->
        if a < 256 then [(a,255)] else []
    | (a1,b1)::r ->
        if a < a1 then (a,a1-1)::(comp_rec (b1+1) r) else comp_rec (b1+1) r
    in
    comp_rec 0 l

  let interv a b = char_interv (Char.chr a) (Char.chr b)

  let rec make_charset l =
    match l with
      | [] -> empty
      | (a,b)::r -> alt (interv a b) (make_charset r)

}


rule token = parse
  | '\\' _
      { CHAR (lexeme_char lexbuf 1) }
  | '.'
      { CHARSET(interv 0 255) }
  | '*'
      { STAR }
  | '+'
      { PLUS }
  | '?'
      { QUESTION }
  | '|'
      { ALT }
  | '('
      { OPENPAR }
  | ')'
      { CLOSEPAR }
  | "[^"
      { CHARSET(make_charset (complement (charset lexbuf))) }
  | '['
      { CHARSET(make_charset (charset lexbuf)) }
  | _
      { CHAR (lexeme_char lexbuf 0) }
  | eof
      { EOF }

and charset = parse
  | ']'
      { [] }
  | '\\' _
      { let c = Char.code(lexeme_char lexbuf 1) in
    add_inter c c (charset lexbuf) }
  | [^ '\\'] '-' _
      { let c1 = Char.code (lexeme_char lexbuf 0)
    and c2 = Char.code (lexeme_char lexbuf 2)
    in
    add_inter c1 c2 (charset lexbuf) }
  | _
      { let c = Char.code(lexeme_char lexbuf 0) in
    add_inter c c (charset lexbuf) }


