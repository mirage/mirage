
(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU Library General Public License as
  published by the Free Software Foundation, version 2.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Library General Public License for more details.

  You should have received a copy of the GNU Library General Public
  License along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
  USA
*)

open Printf

open Http_types
open Http_constants

(* convention:
   foo_RE_raw  is the uncompiled regexp matching foo
   foo_RE      is the compiled regexp matching foo
   is_foo      is the predicate over string matching foo
*)

let separators_RE_raw = "()<>@,;:\\\\\"/\\[\\]?={} \t"
let ctls_RE_raw = "\\x00-\\x1F\\x7F"
let token_RE_raw = "[^" ^ separators_RE_raw ^ ctls_RE_raw ^ "]+"
let lws_RE_raw = "(\r\n)?[ \t]"
let quoted_string_RE_raw = "\"(([^\"])|(\\\\\"))*\""
let text_RE_raw = "(([^" ^ ctls_RE_raw ^ "])|(" ^ lws_RE_raw ^ "))+"
let field_content_RE_raw =
  sprintf
    "^(((%s)|(%s)|(%s))|(%s))*$"
    token_RE_raw
    separators_RE_raw
    quoted_string_RE_raw
    text_RE_raw
(*
  (* following RFC 2616 specifications *)
let field_value_RE_raw = "((" ^ field_content_RE_raw ^ ")|(" ^ lws_RE_raw^ "))*"
*)
  (* smarter implementation: TEXT production is included in the regexp below *)
let field_value_RE_raw =
  sprintf
    "^((%s)|(%s)|(%s)|(%s))*$"
    token_RE_raw
    separators_RE_raw
    quoted_string_RE_raw
    lws_RE_raw

let token_RE = Pcre.regexp ("^" ^ token_RE_raw ^ "$")
let field_value_RE = Pcre.regexp ("^" ^ field_value_RE_raw ^ "$")
let heading_lws_RE = Pcre.regexp (sprintf "^%s*" lws_RE_raw)
let trailing_lws_RE = Pcre.regexp (sprintf "%s*$" lws_RE_raw)

let is_token s = Pcre.pmatch ~rex:token_RE s
let is_field_name = is_token
let is_field_value s = Pcre.pmatch ~rex:field_value_RE s

let heal_header_name s =
  if not (is_field_name s) then raise (Invalid_header_name s) else ()

let heal_header_value s =
  if not (is_field_value s) then raise (Invalid_header_value s) else ()

let normalize_header_value s =
  Pcre.replace ~rex:trailing_lws_RE
    (Pcre.replace ~rex:heading_lws_RE s)

let heal_header (name, value) =
  heal_header_name name;
  heal_header_value name
