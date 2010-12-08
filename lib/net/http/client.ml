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

open Printf
open Http_common
open Lwt

type headers = (string * string) list

type tcp_error_source = Connect | Read | Write
exception Tcp_error of tcp_error_source * exn
exception Http_error of (int * headers * string)  (* code, body *)
exception Invalid_url

let url_RE = Str.regexp "^[hH][tT][tT][pP]://\\([a-zA-Z.-]+\\)\\(:[0-9]+\\)?\\(/.*\\)?"

let tcp_bufsiz = 4096 (* for TCP I/O *)

let parse_url url =
  try
    if not (Str.string_match url_RE url 0) then raise Invalid_url;
    let host = Str.matched_group 1 url in
    let port = try
        let port_s = Str.matched_group 2 url in
        int_of_string (String.sub port_s 1 (String.length port_s - 1))
      with _ -> 80 in
    let path = try Str.matched_group 3 url with Not_found -> "/" in
    (host, port, path)
  with exc ->
    failwith
      (sprintf "Can't parse url: %s (exception: %s)"
        url (Printexc.to_string exc))

let content_length_header s = 
  "Content-Length", s 

let default_content_type_h =
  "Content-Type", "application/x-www-form-urlencoded"

let build_req_header headers meth address path =
  let content_length_h s = content_length_header (string_of_int (String.length s)) in
  let headers = default_content_type_h :: content_length_h :: headers in
  let hdrcnt = List.length headers in
  let add_header ht (n, v) = (Hashtbl.replace ht n v; ht) in
  let hdrht = List.fold_left add_header (Hashtbl.create hdrcnt) headers in
  let serialize_header name value prev =
    sprintf "%s\r\n%s: %s" prev name value in
  let hdrst = Hashtbl.fold serialize_header hdrht "" in
  sprintf "%s %s HTTP/1.0%s\r\n\r\n" meth path hdrst

let request outchan headers meth body (address, _, path) =
  let headers = match headers with None -> [] | Some hs -> hs in
  let req_header = build_req_header headers meth address path in
  lwt () = Flow.write_all outchan req_header in
  lwt () = match body with
    | None   -> return ()
    | Some s -> Flow.write_all outchan s

let read_response inchan =
  lwt (_, status) = Http_parser.parse_response_fst_line inchan in
  lwt headers = Http_parser.parse_headers inchan in
  let headers = List.map (fun (h, v) -> (String.lowercase h, v)) headers in
  lwt resp = Flow.read_all inchan in
  match code_of_status status with
    | 200 -> return (headers, resp)
    | code -> fail (Http_error (code, headers, resp))

let connect (address, port, _) iofn =
  lwt sockaddr = Http_misc.build_sockaddr (address, port) in
  Flow.with_connection sockaddr iofn
    
let call headers kind request_body url =
  let meth = match kind with
    | `GET -> "GET"
    | `HEAD -> "HEAD"
    | `PUT -> "PUT" 
    | `DELETE -> "DELETE" 
    | `POST -> "POST" in
  let endp = parse_url url in
  try_lwt connect endp
    (fun t ->
      (try_lwt request t headers meth request_body endp
       with exn -> fail (Tcp_error (Write, exn))
      ) >>
      (try_lwt read_response t
       with
         | (Http_error _) as e -> fail e
         | exn                 -> fail (Tcp_error (Read, exn))))
  with
    | (Tcp_error _ | Http_error _) as e -> fail e
    | exn                               -> fail (Tcp_error (Connect, exn))

let head   ?headers       url = call headers `HEAD   None url
let get    ?headers       url = call headers `GET    None url
let post   ?headers ?body url = call headers `POST   body url
let put    ?headers ?body url = call headers `PUT    body url
let delete ?headers       url = call headers `DELETE None url
