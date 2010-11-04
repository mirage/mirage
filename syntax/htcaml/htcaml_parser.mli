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

val main :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Htcaml_ast.t
