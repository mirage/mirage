
let from_string s =
  try
    let b = Lexing.from_string s in
    Regexp_parser.regexp_start Regexp_lexer.token b
  with
      Parsing.Parse_error -> invalid_arg "from_string"



