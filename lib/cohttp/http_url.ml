(*
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(* From http://www.blooberry.com/indexdot/html/topics/urlencoding.htm#how *)
let url_encoding = Pcre.regexp (
  "([\\x00-\\x1F\\x7F" ^ (* ASCII control chars *)
  "\\x80-\\xFF" ^ (* non-ASCII chars *)
  "\\x24\\x26\\x2B\\x2C\\x2F\\x3A\\x3B\\x3D\\x3F\\x40" ^ (* Reserved chars *)
  "\\x20\\x22\\x3C\\x3E\\x23\\x25\\x7B\\x7D\\x7C\\x5C\\x5E\\x7E\\x5B\\x5D\\x60])" (* unsafe chars *)
)

let encoding c =
	Printf.sprintf "%%%X" (Char.code c.[0])
	
let encode str =
	Pcre.substitute ~rex:url_encoding ~subst:encoding str

let url_decoding = Pcre.regexp "(%[0-9][0-9])"

let decoding str =
  let s = String.create 4 in
  s.[0] <- '0';
  s.[1] <- 'x';
  s.[2] <- str.[1];
  s.[3] <- str.[2];
  String.make 1 (Char.chr (int_of_string s))
 
let decode str =
  Pcre.substitute ~rex:url_decoding ~subst:decoding str

(*let _ =
  let i = "foo$bar$"in
  let e = encode i in
  let d = decode e in
	Printf.printf "init: %s\nencode : %s\ndecode: %s" i e d
*)

type t = {
	scheme : string option;
	userinfo: string option;
	host : string;
	port: int option;
	path : string option;
	query : string option;
	fragment : string option;
}

let path t = t.path
let query t = t.query

(* From http://www.filbar.org/weblog/parsing_incomplete_or_malformed_urls_with_regular_expressions *)
let url_regexp = Pcre.regexp (
  "^((?<scheme>[A-Za-z0-9_+.]{1,8}):)?(//)?" ^
  "((?<userinfo>[!-~]+)@)?" ^
  "(?<host>[^/?#:]*)(:(?<port>[0-9]*))?" ^
  "(/(?<path>[^?#]*))?" ^
  "(\\?(?<query>[^#]*))?" ^
  "(#(?<fragment>.*))?" )


(*let _ =
	let get n s =
		try Printf.printf "%s: %s\n%!" n (Pcre.get_named_substring regexp n s)
		with Not_found -> Printf.printf "%s: <none>\n%!" n in
	let url = (Pcre.exec ~rex:regexp "http://foo.com/vi/vu.html") in
	get "scheme" url;
	get "host" url;
	get "fragment" url
*)

let of_string str =
  try
	  let url = Pcre.exec ~rex:url_regexp str in
	  let get n =
		  try Some (Pcre.get_named_substring url_regexp n url)
		  with Not_found -> None in
	  {
		  scheme = get "scheme";
		  userinfo = get "userinfo";
		  host = (match get "host" with None -> failwith "of_string" | Some x -> x);
		  port = (match get "port" with Some p -> Some (int_of_string p) | None -> None);
		  path = get "path";
		  query = get "query";
		  fragment = get "fragment";
	  }
  with _ -> raise (Http_types.Malformed_URL str)
	
open Printf

let to_string url =
  let scheme = match url.scheme with
    | Some s -> sprintf "%s://" s
    | None   -> "" in
  let userinfo = match url.userinfo with
    | Some s -> sprintf "%s@" s
    | None   -> "" in
  let host = url.host in
  let port = match url.port with
    | Some i -> sprintf ":%d" i
    | None   -> "" in
  let path = match url.path with
    | Some s -> sprintf "/%s" s
    | None   -> "" in
  let query = match url.query with
    | Some s -> sprintf "?%s" s
    | None   -> "" in
  let fragment = match url.fragment with
    | Some s -> sprintf "#%s" s
    | None   -> "" in
  encode (sprintf "%s%s%s%s%s%s%s" scheme userinfo host port path query fragment)
  
