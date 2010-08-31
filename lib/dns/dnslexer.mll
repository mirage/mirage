(*
   dnslexer.mll -- ocamllex lexer for DNS "Master zone file" format
   Copyright (c) 2006 Tim Deegan <tjd@phlegethon.org>
*)

(* DNS master zonefile format is defined in RFC 1035, section 5.
   Escapes and octets are clarified in RFC 4343 *)
   
{

open Dnsloader
open Dnsparser
open Lexing
open Str

(* Remove magic escapes from a string *)
let unescape s = 
  let re_escape = regexp "\\\\." in
  let re_octet = regexp "\\\\[0-9][0-9][0-9]" in
  let rec copy_unescaped src dst slen soff doff = 
    if soff >= slen then doff 
    else if string_match re_octet src soff then begin
      dst.[doff] <- char_of_int (int_of_string (String.sub s (soff + 1) 3));
      copy_unescaped src dst slen (soff + 4) (doff + 1)
    end else if string_match re_escape src soff then begin 
      dst.[doff] <- src.[soff + 1]; 
      copy_unescaped src dst slen (soff + 2) (doff + 1)
    end else begin
      dst.[doff] <- src.[soff];
      copy_unescaped src dst slen (soff + 1) (doff + 1)
    end
  in let slen = String.length s
  in let d = String.create slen
  in let dlen = copy_unescaped s d slen 0 0 
  in CHARSTRING (String.sub d 0 dlen)


(* Disambiguate keywords and generic character strings *)
let kw_or_cs s = match (String.uppercase s) with 
    "A" -> TYPE_A s
  | "NS" -> TYPE_NS s 
  | "MD" -> TYPE_MD s
  | "MF" -> TYPE_MF s
  | "CNAME" -> TYPE_CNAME s
  | "SOA" -> TYPE_SOA s
  | "MB" -> TYPE_MB s
  | "MG" -> TYPE_MG s
  | "MR" -> TYPE_MR s
  | "NULL" -> TYPE_NULL s
  | "WKS" -> TYPE_WKS s
  | "PTR" -> TYPE_PTR s
  | "HINFO" -> TYPE_HINFO s
  | "MINFO" -> TYPE_MINFO s
  | "MX" -> TYPE_MX s
  | "TXT" -> TYPE_TXT s
  | "RP" -> TYPE_RP s
  | "AFSDB" -> TYPE_AFSDB s
  | "X25" -> TYPE_X25 s
  | "ISDN" -> TYPE_ISDN s
  | "RT" -> TYPE_RT s
  | "NSAP" -> TYPE_NSAP s
  | "NSAP-PTR" -> TYPE_NSAP_PTR s
  | "SIG" -> TYPE_SIG s
  | "KEY" -> TYPE_KEY s
  | "PX" -> TYPE_PX s
  | "GPOS" -> TYPE_GPOS s
  | "AAAA" -> TYPE_AAAA s
  | "LOC" -> TYPE_LOC s
  | "NXT" -> TYPE_NXT s
  | "EID" -> TYPE_EID s
  | "NIMLOC" -> TYPE_NIMLOC s
  | "SRV" -> TYPE_SRV s
  | "ATMA" -> TYPE_ATMA s
  | "NAPTR" -> TYPE_NAPTR s
  | "KX" -> TYPE_KX s
  | "CERT" -> TYPE_CERT s
  | "A6" -> TYPE_A6 s
  | "DNAME" -> TYPE_DNAME s
  | "SINK" -> TYPE_SINK s
  | "OPT" -> TYPE_OPT s
  | "APL" -> TYPE_APL s
  | "DS" -> TYPE_DS s
  | "SSHFP" -> TYPE_SSHFP s
  | "IPSECKEY" -> TYPE_IPSECKEY s
  | "RRSIG" -> TYPE_RRSIG s
  | "NSEC" -> TYPE_NSEC s
  | "DNSKEY" -> TYPE_DNSKEY s
  | "SPF" -> TYPE_SPF s
  | "UINFO" -> TYPE_UINFO s
  | "UID" -> TYPE_UID s
  | "GID" -> TYPE_GID s
  | "UNSPEC" -> TYPE_UNSPEC s
  | "TKEY" -> TYPE_TKEY s
  | "TSIG" -> TYPE_TSIG s
  | "MAILB" -> TYPE_MAILB s
  | "MAILA" -> TYPE_MAILA s
  | "IN" -> CLASS_IN s
  | "CS" -> CLASS_CS s
  | "CH" -> CLASS_CH s
  | "HS" -> CLASS_HS s
  | _ -> unescape s


(* Scan an accepted token for linebreaks *)
let count_linebreaks s = 
  String.iter (function '\n' -> state.lineno <- state.lineno + 1 | _ -> ()) s


} 

let eol = [' ''\t']* (';' [^'\n']*)? '\n' 
let octet = '\\' ['0'-'9'] ['0'-'9'] ['0'-'9']
let escape = '\\' _ (* Strictly \0 is not an escape, but be liberal *)
let qstring = '"' ((([^'\\''"']|octet|escape)*) as contents) '"'
let label = (([^'\\'' ''\t''\n''.''('')']|octet|escape)*) as contents
let number = (['0'-'9']+) as contents
let openpar = [' ''\t']* '(' ([' ''\t''\n'] | eol)*
let closepar = (eol | [' ''\t''\n'])* ')' [' ''\t']*
let typefoo = (['T''t']['Y''y']['P''p']['E''e'] number) as contents

rule token = parse
  eol           { state.lineno <- state.lineno + 1;
	          if state.paren > 0 then SPACE else EOL }
| openpar       { state.paren <- state.paren + 1; 
	          count_linebreaks (lexeme lexbuf); SPACE }
| closepar      { if state.paren > 0 then state.paren <- state.paren - 1;
	          count_linebreaks (lexeme lexbuf); SPACE }
| closepar eol  { if state.paren > 0 then state.paren <- state.paren - 1;
	          count_linebreaks (lexeme lexbuf); EOL }
| "\\#"         { GENERIC }
| "$ORIGIN"     { SORIGIN }
| "$TTL"        { STTL }
| '.'           { DOT }
| '@'           { AT }
| number        { NUMBER contents }
| typefoo       { TYPE_GENERIC contents }
| qstring       { count_linebreaks contents; unescape contents }
| label         { count_linebreaks contents; kw_or_cs contents }
| [' ''\t']+    { SPACE }
| eof           { EOF }

