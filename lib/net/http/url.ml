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
let url_encoding = Str.regexp (
  "[\x00-\x1F\x7F" ^ (* ASCII control chars *)
  "\x80-\xFF" ^ (* non-ASCII chars *)
  "\x24\x26\x2B\x2C\x2F\x3A\x3B\x3D\x3F\x40" ^ (* Reserved chars *)
  "\x20\x22\x3C\x3E\x23\x25\x7B\x7D\x7C\x5C\x5E\x7E\x5B\\x5D\x60]" (* unsafe chars *)
)

let encoding str =
  let c = Str.matched_string str in
  Printf.sprintf "%%%X" (Char.code c.[0])
  
let encode str =
  Str.global_substitute url_encoding encoding str

let url_decoding = Str.regexp "%[0-9][0-9]"

let decoding str =
  let str = Str.matched_string str in
  let s = String.create 4 in
  s.[0] <- '0';
  s.[1] <- 'x';
  s.[2] <- str.[1];
  s.[3] <- str.[2];
  String.make 1 (Char.chr (int_of_string s))
 
let decode str =
  Str.global_substitute url_decoding decoding str

(*
let _ =
  let i = "foo$bar$"in
  let e = encode i in
  let d = decode e in
  Printf.printf "init: %s\nencode : %s\ndecode: %s\n" i e d
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
let url_regexp = Str.regexp (
  "\\(\\([A-Za-z0-9_+.]+\\):\\)?\\(//\\)?" ^ (* scheme *)
  "\\(\\([!-~]+\\)@\\)?" ^                   (* userinfo *)
  "\\([^/?#:]*\\)" ^                         (* host *)
  "\\(:\\([0-9]*\\)\\)?" ^                   (* port *)
  "\\(/\\([^?#]*\\)\\)?" ^                   (* path *)
  "\\(\\?\\([^#]*\\)\\)?" ^                  (* query *)
  "\\(#\\(.*\\)\\)?"                         (* fragment *)
)

type url_fragments = Scheme | Userinfo | Host | Port | Path | Query | Fragment

let names = [
  Scheme,   2;
  Userinfo, 5;
  Host,     6;
  Port,     8;
  Path,     10;
  Query,    12;
  Fragment, 14;
]

let get n str =
  try Some (Str.matched_group (List.assoc n names) str)
  with Not_found -> None

(*
let _ =
  let url = "foo://john.doo@example.com:8042/over/there?name=ferret#nose" in
  let get n s =
    match get n url with
    | Some x -> Printf.printf "%s: %s\n%!" n x
    | None   -> Printf.printf "%s: <none>\n%!" n in
  if Str.string_match url_regexp url 0 then begin
    get "scheme" url;
    get "userinfo" url;
    get "host" url;
    get "port" url;
    get "path" url;
    get "query" url;
    get "fragment" url
  end else
    Printf.printf "URL don't match !!!\n"
*)

let of_string str =
  if Str.string_match url_regexp str 0 then
    let get n = get n str in
    {
      scheme = get Scheme;
      userinfo = get Userinfo;
      host = (match get Host with None -> failwith "of_string" | Some x -> x);
      port = (match get Port with Some p -> Some (int_of_string p) | None -> None);
      path = get Path;
      query = get Query;
      fragment = get Fragment;
    }
  else raise (Types.Malformed_URL str)
  
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
  
