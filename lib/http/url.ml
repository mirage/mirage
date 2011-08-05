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

open Regexp (*makes module Re accessible*)

(* From http://www.blooberry.com/indexdot/html/topics/urlencoding.htm#how *)
let url_encoding = Re.from_string (
  "[\x00-\x1F\x7F" ^                                       (* ASCII control *)
  "\x80-\xFF" ^                                                (* non-ASCII *)
  "\x24\x26\x2B\x2C\x2F\x3A\x3B\x3D\x3F\x40" ^                  (* Reserved *)
  "\x20\x22\x3C\x3E\x23\x25\x7B\x7D\x7C\x5C\x5E\x7E\x5B\x5D\x60]" (* Unsafe *)
)

let encoding str =
  Printf.sprintf "%%%X" (Char.code str.[0])

let encode str =
  Re.substitute url_encoding str encoding

let url_decoding = Re.from_string "%[0-9][0-9]"

let decoding str =
  let s = String.create 4 in
  s.[0] <- '0';
  s.[1] <- 'x';
  s.[2] <- str.[1];
  s.[3] <- str.[2];
  String.make 1 (Char.chr (int_of_string s))

let decode str =
  Re.substitute url_decoding str decoding

type t = {
  scheme       : string option;
  userinfo     : string option;
  host         : string;
  port         : int option;
  path         : string list option;
  path_string  : string option;
  query        : (string * string) list option;
  query_string : string option;
  fragment     : string option;
}

let host u = u.host
let port u = u.port
let path u = u.path
let query u = u.query

let full_path t =
  let p1 = match t.path_string with
    | None   -> "/"
    | Some p -> "/" ^ p in
  let p2 = match t.query_string with
    | None   -> ""
    | Some q -> "?" ^ q in
  let p3 = match t.fragment with
    | None   -> ""
    | Some f -> "#" ^ f in
  p1 ^ p2 ^ p3


let of_string str = failwith "TODO"



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
  let path = match url.path_string with
    | Some s -> sprintf "/%s" s
    | None   -> "" in
  let query = match url.query_string with
    | Some s -> sprintf "?%s" s
    | None   -> "" in
  let fragment = match url.fragment with
    | Some s -> sprintf "#%s" s
    | None   -> "" in
  encode
    (sprintf "%s%s%s%s%s%s%s" scheme userinfo host port path query fragment)

