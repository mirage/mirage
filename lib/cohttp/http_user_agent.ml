(*pp camlp4o -I `ocamlfind query lwt.syntax` pa_lwt.cmo *)

(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
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

module IO = Unix.IO

open Printf
open Http_common
open Lwt

type headers = (string * string) list

type tcp_error_source = Connect | Read | Write
exception Tcp_error of tcp_error_source * exn
exception Http_error of (int * headers * string)  (* code, body *)

let http_scheme_RE = Pcre.regexp ~flags:[`CASELESS] "^http://"
let url_RE = Pcre.regexp "^([\\w.-]+)(:(\\d+))?(/.*)?$"

let tcp_bufsiz = 4096 (* for TCP I/O *)

let parse_url url =
  try
    let subs =
      Pcre.extract ~rex:url_RE (Pcre.replace ~rex:http_scheme_RE url)
    in
    (subs.(1),
    (if subs.(2) = "" then 80 else int_of_string subs.(3)),
    (if subs.(4) = "" then "/" else subs.(4)))
  with exc ->
    failwith
      (sprintf "Can't parse url: %s (exception: %s)"
        url (Printexc.to_string exc))

let build_req_string headers meth address path body =
  let content_type = ("Content-Type", "application/x-www-form-urlencoded") in
  let content_length s = ("Content-Length", string_of_int (String.length s)) in
  let body, headers = match body with
    | None -> "", headers
    | Some s -> s, content_type::(content_length s)::headers in
  let headers = ("Host", address)::headers in
  let hdrcnt = List.length headers in
  let add_header ht (n, v) = (Hashtbl.replace ht n v; ht) in
  let hdrht = List.fold_left add_header (Hashtbl.create hdrcnt) headers in
  let serialize_header name value prev =
    sprintf "%s\r\n%s: %s" prev name value in
  let hdrst = Hashtbl.fold serialize_header hdrht "" in
    sprintf "%s %s HTTP/1.0%s\r\n\r\n%s" meth path hdrst body

let request outchan headers meth body (address, _, path) =
  let headers = match headers with None -> [] | Some hs -> hs in
    IO.write outchan (build_req_string headers meth address path body)
    >> IO.flush outchan

let read inchan =
  lwt (_, status) = Http_parser.parse_response_fst_line inchan in
  lwt headers = Http_parser.parse_headers inchan in
  let headers = List.map (fun (h, v) -> (String.lowercase h, v)) headers in
  lwt resp = IO.read inchan in
    match code_of_status status with
      | 200 -> return (headers, resp)
      | code -> fail (Http_error (code, headers, resp))

let connect (address, port, _) iofn =
  lwt sockaddr = Http_misc.build_sockaddr (address, port) in
  IO.with_connection ~buffer_size:tcp_bufsiz sockaddr iofn
    
let call headers kind body url =
  let meth = match kind with
    | `GET -> "GET"
    | `HEAD -> "HEAD"
    | `POST -> "POST" in
  let endp = parse_url url in
    try_lwt connect endp
      (fun (i, o) ->
	 (try_lwt request o headers meth body endp
	  with exn -> fail (Tcp_error (Write, exn))
	 ) >> (try_lwt read i
	       with
		 | (Http_error _) as e -> fail e
		 | exn -> fail (Tcp_error (Read, exn))
	      ))
    with
      | (Tcp_error _ | Http_error _) as e -> fail e
      | exn -> fail (Tcp_error (Connect, exn))

let head ?headers url = call headers `HEAD None url
let get  ?headers url = call headers `GET None url
let post ?headers ?body url = call headers `POST body url
