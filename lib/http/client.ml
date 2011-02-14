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
type response_body = OS.Istring.View.t Lwt_sequence.t Lwt.t
exception Invalid_url
exception Http_error of int * headers * response_body
exception Not_implemented of string

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

let do_request chan headers meth body (address, _, path) : unit Lwt.t =
  let headers = match headers with None -> [] | Some hs -> hs in
  let req_header = build_req_header headers meth address path body in
  OS.Console.log (Printf.sprintf "[REQUEST] %s" req_header);
  Net.Channel.TCPv4.write_string chan req_header >>
  (match body with
  |None -> return ()
  |Some s -> Net.Channel.TCPv4.write_string chan s) >>
  Net.Channel.TCPv4.flush chan

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

let read_response (chan:Net.Channel.TCPv4.t) : (headers * response_body) Lwt.t =
  let read_line () = Net.Channel.TCPv4.read_line chan in
  lwt (_, status) = Parser.parse_response_fst_line read_line in
  lwt headers = Parser.parse_headers read_line in
  let content_length_opt = content_length_of_content_range headers in
  (* a status code of 206 (Partial) will typically
     accompany "Content-Range" response header *)
  let (resp: OS.Istring.View.t Lwt_sequence.t Lwt.t) = 
    match content_length_opt with
      |Some (count:int) -> Net.Channel.TCPv4.read_view chan count
      |None -> Net.Channel.TCPv4.read_all chan
  in
  match code_of_status status with
    |200 |206 -> return (headers, resp)
    |code      -> fail (Http_error (code, headers, resp))

let call mgr ?src ?headers kind request_body url: (headers * response_body) Lwt.t  =
  let meth = match kind with
    |`GET -> "GET"
    |`HEAD -> "HEAD"
    |`PUT -> "PUT" 
    |`DELETE -> "DELETE" 
    |`POST -> "POST"
  in
  let endp = parse_url url in
  let host, port, path = endp in
  (* TODO DNS resolution! *)
  lwt dst_ip = match Net.Nettypes.ipv4_addr_of_string host with
    |Some ip -> return ip
    |None -> fail (Not_implemented "dns resolution: specify url as ip")
  in
  let dst = dst_ip, port in
  Net.Flow.TCPv4.connect mgr ?src dst (fun t ->
    let channel = Net.Channel.TCPv4.create t in
    lwt () = do_request channel headers meth request_body endp in
    lwt res = read_response channel in return res
  )

let head   mgr ?src ?headers       url = call mgr ?src ?headers `HEAD   None url
let get    mgr ?src ?headers       url = call mgr ?src ?headers `GET    None url
let post   mgr ?src ?headers ?body url = call mgr ?src ?headers `POST   body url
let put    mgr ?src ?headers ?body url = call mgr ?src ?headers `PUT    body url
let delete mgr ?src ?headers       url = call mgr ?src ?headers `DELETE None url
