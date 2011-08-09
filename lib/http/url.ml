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

let url_decoding = Re.from_string "%[0-9a-fA-F][0-9a-fA-F]"

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
  host         : string option;
  port         : int option;
  path         : string list option;
  path_string  : string option;
  query        : (string * string) list option;
  query_string : string option;
  fragment     : string option;
}

let debug_print s t =
  let unopt = function
    | None -> ""
    | Some s -> s
  in
  Printf.sprintf
    "RAW:%s SCHEME:%s USERINFO:%s HOST:%s PORT:%i PATH:%s QUERY:%s FRAGMENT:%s\n"
    s
    (unopt t.scheme)
    (unopt t.userinfo)
    (unopt t.host)
    (match t.port with None -> (-1) | Some p -> p)
    (unopt t.path_string)
    (unopt t.query_string)
    (unopt t.fragment)

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


module Of_string = struct

  let none_url =
    { scheme       = None
    ; userinfo     = None
    ; host         = None
    ; port         = None
    ; path         = None
    ; path_string  = None
    ; query        = None
    ; query_string = None
    ; fragment     = None
    }

  let scheme_re   = Re.from_string "([^:/?#]+):"
  let host_re     = Re.from_string "//([^/?#]*)"
  let path_re     = Re.from_string "[^?#]*"
  let query_re    = Re.from_string "\\?([^#]*)"
  let fragment_re = Re.from_string "#(.*)"

  let scheme   str     = Re.match_string scheme_re   str 0
  let host     str off = Re.match_string host_re     str off
  let path     str off = Re.match_string path_re     str off
  let query    str off = Re.match_string query_re    str off
  let fragment str off = Re.match_string fragment_re str off

  let of_string_fragment str off =
    match fragment str off with
    | None -> none_url
    | Some o ->
      { none_url with
        fragment = Some (String.sub str (succ off) (o - (succ off)))
                                        (*'succ' gets rid of '#'*)
      }

  let of_string_query str off =
    match query str off with
    | None -> of_string_fragment str off
    | Some o ->
      {(of_string_fragment str o) with
        query_string = Some (String.sub str (succ off) (o - (succ off)))
                                            (*'succ' gets rid of '?'*)
      }

  let of_string_path str off =
    match path str off with
    | None -> of_string_query str off
    | Some o ->
      {(of_string_query str o)
        with path_string = Some (String.sub str off (o - off))
      }

  let of_string_host str off =
    match host str off with
    | None -> of_string_path str off
    | Some o ->
      {(of_string_path str o) with
        host = Some (String.sub str (off + 2) (o - (off + 2)))
                                    (*'+ 2' gets rid of '//'*)
      }

  let of_string str =
    match scheme str with
    | None -> of_string_host str 0
    | Some o ->
      {(of_string_host str o) with
        scheme = Some (String.sub str 0 (pred o))(*'pred' gets rid of ':'*)
      }

  let path_delim     = Re.from_string "/"
  let query_delim    = Re.from_string "&"
  let query_subdelim = Re.from_string "="
  let userinfo_delim = Re.from_string "@"
  let port_delim     = Re.from_string ":"

  let polish url =
    let url =
      match url.host with
      | None -> url
      | Some s -> (*check for userinfo*)
        match Re.search_forward userinfo_delim s 0 with
        | None -> url
        | Some (b,e) ->
          { url with
            userinfo = Some (String.sub s 0 (pred b)) ;
            host     = Some (String.sub s e (String.length s - e)) ;
          }
    in
    let url = (*/!\ does NOT support IPv6 addresses*)
      match url.host with
      | None -> url
      | Some s -> (*check for port*)
        match Re.search_forward port_delim s 0 with
        | None -> url
        | Some (b,e) ->
          { url with
            host = Some (String.sub s 0 (pred b)) ;
            port = Some (int_of_string (String.sub s e (String.length s - e))) ;
          }
    in
    { url with
      path = begin
        match url.path_string with
        | None -> None
        | Some s -> Some (Re.split_delim path_delim s)
      end ;
      query = begin
        match url.query_string with
        | None -> None
        | Some s ->
          let bits = Re.split_delim query_delim s in
          let bitbits =
            List.map
              (fun s -> match Re.search_forward query_subdelim s 0 with
                | None -> (s,"")
                | Some (b,e) ->
                  (String.sub s 0 (pred b)
                  ,String.sub s e (String.length s - e)
                  )
              )
              bits
          in
          Some bitbits
      end
    }

end

let of_string str =
  let r =
    Of_string.polish (Of_string.of_string str)
  in
  print_endline (debug_print str r);
  r




open Printf

let to_string url =
  let scheme = match url.scheme with
    | Some s -> sprintf "%s://" s
    | None   -> "" in
  let userinfo = match url.userinfo with
    | Some s -> sprintf "%s@" s
    | None   -> "" in
  let host = match url.host with
    | Some s -> s
    | None   -> "" in
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

