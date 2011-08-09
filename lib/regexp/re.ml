
type regexp = Regular_expr.regexp

let empty = Regular_expr.empty
let epsilon = Regular_expr.epsilon
let char = Regular_expr.char
let char_interv = Regular_expr.char_interv
let string = Regular_expr.string
let star = Regular_expr.star
let alt = Regular_expr.alt
let seq = Regular_expr.seq
let opt = Regular_expr.opt
let some = Regular_expr.some

let from_string_raw = Regexp_syntax.from_string



type compiled_regexp = Automata.automaton

let compile = Automata.compile
let from_string s = compile (Regexp_syntax.from_string s)

let match_string = Automata.match_string
let search_forward cre s i =
  try
    Some (Automata.search_forward cre s i)
  with
    | Not_found -> None
let list_matches = Automata.split_strings
let split_delim = Automata.split_delim
let replace = Automata.replace
let substitute = Automata.substitute


