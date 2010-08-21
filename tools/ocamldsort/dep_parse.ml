(***********************************************************************)
(*                           ocamldsort                                *)
(*                                                                     *)
(*                 Copyright (C) 2002  Dimitri Ara                     *)
(*                                                                     *)
(* This program is free software; you can redistribute it and/or       *)
(* modify it under the terms of the GNU General Public License         *)
(* as published by the Free Software Foundation; either version 2      *)
(* of the License, or (at your option) any later version.              *)
(*                                                                     *)
(* This program is distributed in the hope that it will be useful,     *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of      *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       *)
(* GNU General Public License for more details.                        *)
(*                                                                     *)
(* You should have received a copy of the GNU General Public License   *)
(* along with this program; if not, write to the Free Software         *)
(* Foundation, Inc.,                                                   *)
(* 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.           *)
(***********************************************************************)

exception Parse_error

let string_of_char c = String.make 1 c

let concat char string =
  string_of_char char ^ string

let rec parse_source = parser
  | [< '' ' >] -> ("", true)
  | [< ''\n' >] -> ("", false)
  | [< 'a;  (d, cont) = parse_source >] -> (concat a d, cont)

let rec parse_sources = parser
  | [< '' '; d = parse_sources >] -> d
  | [< ''\\'; ''\n'; d = parse_sources >] -> d
  | [< ''\n' >] -> []
  | [< 'a; (d, cont) = parse_source;
       ds = if cont then parse_sources else (fun _ -> []) >] ->
         (Files.file_of_filename (concat a d)) :: ds

let rec parse_target = parser
  | [< '':' >] -> ""
| [< 'a;  n = parse_target >] -> concat a n

let rec parse_ocamldep stream =
  try
    (match stream with parser
       | [< t = parse_target; d = parse_sources; ds = parse_ocamldep >] ->
	   if not (Files.is_cmx t) then
	     (Files.file_of_filename t, d) :: ds
	   else
	      ds
       | [< >] -> [])
  with 
    | Stream.Failure ->
	raise Parse_error
    | Stream.Error _ ->
	raise Parse_error
