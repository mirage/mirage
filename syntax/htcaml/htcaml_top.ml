(* following Ocamlnet's netstring_top.ml *)

let exec s =
  let l = Lexing.from_string s in
  let ph = !Toploop.parse_toplevel_phrase l in
  assert(Toploop.execute_phrase false Format.err_formatter ph)
;;

exec "#install_printer Jq_printer.t;;";;
