(*

  This module provides compilation of a regexp into an automaton. It
  then provides some functions for matching and searching.

  Refer to re.mli for detailed semantic.

*)


type automaton


val compile : Regular_expr.regexp -> automaton


val exec_automaton : automaton -> string -> int -> int
val match_string   : automaton -> string -> int -> int option
val search_forward : automaton -> string -> int -> int * int
val split_strings  : automaton -> string -> string list
val split_delim    : automaton -> string -> string list
val replace        : automaton -> string -> string -> string
val substitute     : automaton -> string -> (string -> string) -> string

