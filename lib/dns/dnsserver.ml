(*
   dnsserver.ml -- an authoritative DNS server
   Copyright (c) 2005-2006 Tim Deegan <tjd@phlegethon.org>
*)

open Dnsloader

(* Load a zone from a string buffer *)
let load_zone origin buf =
  try 
    let lexbuf = Lexing.from_string buf in
    state.paren <- 0;
    state.filename <- "<string>";
    state.lineno <- 1;
    state.origin <- List.map String.lowercase origin;
    state.ttl <- Int32.of_int 3600;
    state.owner <- state.origin;
    Dnsparser.zfile Dnslexer.token lexbuf
  with
  | Parsing.Parse_error -> ()


(* Testing *)
(* 

open Dnsloader;;
open Dnsquery;;
open Dnsserver;;
module L = Dnslexer;;

let do_lookup qname qtype = 
  print_string (";; QUERY " ^ (String.concat "." qname) ^ " "
		^ (qtype_to_string qtype) ^ "\n");
  let answer = answer_query qname qtype `IN L.state.L.db.trie
  in print_string (answer_to_string answer)
;;

load_zone [] "root.hints";;
load_zone ["example";"COM"] "test.zone";;

do_lookup ["example";"com"] `MX;; 

do_lookup ["lists";"example";"com"] `ANY;; 

do_lookup ["badname";"example";"com"] `TXT;;
do_lookup ["one";"example";"com"] `ANY;;

*)
