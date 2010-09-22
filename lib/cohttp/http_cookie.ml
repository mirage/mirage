
(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2009> David Sheets <sheets@alum.mit.edu>

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

module OS = Unix
type time = [ `Day of int | `Hour of int | `Minute of int | `Second of int ] list
type expiration = [ `Discard | `Session | `Age of time | `Until of float ]

type cookie = { value : string;
		expiration : expiration;
		domain : string option;
		path : string option;
		secure : bool }

(* Does not check the contents of name or value for ';', ',', '\s', or name[0]='$' *)
let make ?(expiry=`Session) ?path ?domain ?(secure=false) n v =
  (n, { value = v;
	expiration = expiry; domain = domain;
	path = path; secure = secure })
    
let duration tml =
  let tval = function
    | `Day d -> 86400*d
    | `Hour h -> 3600*h
    | `Minute m -> 60*m
    | `Second s -> s
  in List.fold_left (fun a t -> a + (tval t)) 0 tml

let serialize_1_1 (n, c) =
  let attrs = ["Version=1"] in
  let attrs = if c.secure then ("Secure" :: attrs) else attrs in
  let attrs = match c.path with None -> attrs
    | Some p -> ("Path=" ^ p) :: attrs in
  let attrs = match c.expiration with
    | `Discard -> "Max-Age=0" :: attrs
    | `Session -> "Discard" :: attrs
    | `Until stamp ->
	let offset = int_of_float (stamp -. (OS.Clock.time ())) in
	  ("Max-Age=" ^ (string_of_int (min 0 offset))) :: attrs
    | `Age tml -> ("Max-Age=" ^ (string_of_int (duration tml))) :: attrs in
  let attrs = match c.domain with None -> attrs
    | Some d -> ("Domain=" ^ d) :: attrs in
    ("Set-Cookie2", String.concat "; " attrs)
  
let serialize_1_0 (n, c) =
  let fmt_time a = Http_misc.rfc822_of_float a in
  let attrs = if c.secure then ["secure"] else [] in
  let attrs = match c.path with None -> attrs
    | Some p -> ("path=" ^ p) :: attrs in
  let attrs = match c.domain with None -> attrs
    | Some d -> ("domain=" ^ d) :: attrs in
  let attrs = match c.expiration with
    | `Discard -> ("expires=" ^ (fmt_time 0.)) :: attrs
    | `Session -> attrs
    | `Until stamp -> ("expires=" ^ (fmt_time stamp)) :: attrs
    | `Age tml ->
	let age = float (duration tml) in
	  ("expires=" ^ (fmt_time ((OS.Clock.time ()) +. age))) :: attrs in
  let attrs = (n ^ (match c.value with "" -> ""
		      | v -> "=" ^ v)) :: attrs in
    ("Set-Cookie", String.concat "; " attrs)

let serialize ?(version=`HTTP_1_0) cp =
  match version with
    | `HTTP_1_0 -> serialize_1_0 cp
    | `HTTP_1_1 -> serialize_1_1 cp

let extract req =
  List.fold_left
    (fun acc header ->
       let comps = Pcre.split ~rex:(Pcre.regexp "(?:;|,)\\s") header in
       let cookies = List.filter (fun s -> s.[0] != '$') comps in
       let split_pair nvp =
         match Pcre.split ~rex:(Pcre.regexp "=") nvp with
         | [] -> ("","")
         | n :: [] -> (n, "")
         | n :: v :: _ -> (n, v)
       in (List.map split_pair cookies) @ acc
    ) [] (Http_request.header req "Cookie")
