(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
  Copyright (C) <2009> David Sheets <sheets@alum.mit.edu>
  Copyright (C) <2011> Anil Madhavapeddy <anil@recoil.org>

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
open Common
open Lwt

type headers = (string * string) list

type tcp_error_source = Connect | Read | Write
exception Http_error of (int * headers * string)  (* code, body *)
exception Invalid_url

let parse_url url =
  try
    let url  = Url.of_string url in
    let host = Url.host url in
    let port = match Url.port url with
      | None   -> 80
      | Some p -> p in
    let path = Url.full_path url in
    OS.Console.log (Printf.sprintf "[PARSE_URL] host=%s port=%d path=%s" host port path);
    (host, port, path)
  with exc ->
    failwith
      (sprintf "Can't parse url: %s (exception: %s)"
        url (Printexc.to_string exc))

let content_length_header s = 
  "Content-Length", s 

let default_content_type_h =
  "Content-Type", "application/x-www-form-urlencoded"

let build_req_header headers meth address path body =
  let headers =
    match body with
      | None   -> headers
      | Some s ->
        let content_length_h = content_length_header (string_of_int (String.length s)) in
        default_content_type_h :: content_length_h :: headers in
  let hdrcnt = List.length headers in
  let add_header ht (n, v) = (Hashtbl.replace ht n v; ht) in
  let hdrht = List.fold_left add_header (Hashtbl.create hdrcnt) headers in
  let serialize_header name value prev =
    sprintf "%s\r\n%s: %s" prev name value in
  let hdrst = Hashtbl.fold serialize_header hdrht "" in
  sprintf "%s %s HTTP/1.0%s\r\n\r\n" meth path hdrst

let request outchan headers meth body (address, _, path) =
  let headers = match headers with None -> [] | Some hs -> hs in
  let req_header = build_req_header headers meth address path body in
  OS.Console.log (Printf.sprintf "[REQUEST] %s" req_header);
  lwt () = Flow.write_all outchan req_header in
  match body with
    | None   -> return ()
    | Some s -> Flow.write_all outchan s

let id x = x

let parse_content_range s =
  try
    let start, fini, total = Scanf.sscanf s "bytes %d-%d/%d" 
      (fun start fini total -> start, fini, total) 
    in
    Some (start, fini, total)
  with Scanf.Scan_failure _ ->
    None

(* if we see a "Content-Range" header, than we should limit the
   number of bytes we attempt to read *)
let content_length_of_content_range headers = 
  (* assuming header keys were downcased in previous step *)
  if List.mem_assoc "content-length" headers then
    try (let str = List.assoc "content-length" headers in
         let str = Parser_sanity.normalize_header_value str in
         OS.Console.log (Printf.sprintf "---get(%s)" str)
        ; Some (int_of_string str))
    with _ -> (OS.Console.log "---exn"; None)
  else if List.mem_assoc "content-range" headers then
    let range_s = List.assoc "content-range" headers in
    match parse_content_range range_s with
      | Some (start, fini, total) ->
        (* some sanity checking before we act on these values *)
        if fini < total && start <= total && 0 <= start && 0 <= total then (
          let num_bytes_to_read = fini - start + 1 in
          Some num_bytes_to_read
        ) else
          None
      | None -> 
        None
  else
    None    

let read_response inchan =
  lwt (_, status) = Parser.parse_response_fst_line inchan in
  lwt headers = Parser.parse_headers inchan in
  let content_length_opt = content_length_of_content_range headers in
  (* a status code of 206 (Partial) will typicall accompany "Content-Range" 
    response header *)
  lwt resp = 
    match content_length_opt with
      | Some count -> Flow.readn inchan count
      | None       -> Flow.read_all inchan in
  match code_of_status status with
    | 200 | 206 -> return (headers, resp)
    | code      -> fail (Http_error (code, headers, resp))

let connect mgr src dst iofn =
  Flow.TCPv4.connect mgr src dst fn
    
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
