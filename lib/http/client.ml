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
type response_body = Bitstring.t Lwt_stream.t
exception Http_error of int * headers * response_body

let content_length_header s = "Content-Length", s 

let default_content_type_h = "Content-Type", "application/x-www-form-urlencoded"

let build_req_header headers meth address path body =
  let headers =
      match body with
      |None   -> headers
      |Some s ->
        let content_length_h = content_length_header (string_of_int (String.length s)) in
        default_content_type_h :: content_length_h :: headers 
  in
  let hdrcnt = List.length headers in
  let add_header ht (n, v) = (Hashtbl.replace ht n v; ht) in
  let hdrht = List.fold_left add_header (Hashtbl.create hdrcnt) headers in
  let serialize_header name value prev = sprintf "%s\r\n%s: %s" prev name value in
  let hdrst = Hashtbl.fold serialize_header hdrht "" in
  sprintf "%s %s HTTP/1.0%s\r\n\r\n" meth path hdrst

let do_request chan headers meth body (address, _, path) : unit Lwt.t =
  let headers = match headers with None -> [] | Some hs -> hs in
  let req_header = build_req_header headers meth address path body in
  Net.Channel.(write_string chan req_header >>
    match body with
    |None -> flush chan
    |Some s -> write_string chan s >> flush chan)

let id x = x

let read_response chan =
  let read_line () = Net.Channel.read_crlf chan >|= Bitstring.string_of_bitstring in
  lwt (_, status) = Parser.parse_response_fst_line read_line in
  lwt headers = Parser.parse_headers read_line in
  let resp =
    let len = Parser.parse_content_range headers in
    Net.Channel.read_stream ?len chan
  in
  match code_of_status status with
  |200 |206 -> return (headers, resp)
  |code -> fail (Http_error (code, headers, resp))

exception Invalid_url
let parse_url url =
  try
    let url  = Url.of_string url in
    let host = Url.host url in
    let port = match Url.port url with
      |None -> 80
      |Some p -> p in
    let path = Url.full_path url in
    OS.Console.log (Printf.sprintf "[PARSE_URL] host=%s port=%d path=%s" host port path);
    (host, port, path)
  with exc ->
    failwith (sprintf "Can't parse url: %s (exception: %s)" url (Printexc.to_string exc))

(*
let call mgr ?src ?headers kind request_body url =
  let meth = match kind with
    |`GET -> "GET" |`HEAD -> "HEAD" |`PUT -> "PUT" 
    |`DELETE -> "DELETE" |`POST -> "POST" in
  let endp = parse_url url in
  let host, port, path = endp in
  (* TODO DNS resolution! *)
  lwt dst_ip = match Net.Nettypes.ipv4_addr_of_string host with
    |Some ip -> return ip
    |None -> fail (Invalid_url)
  in
  let dst = dst_ip, port in
  Net.Channel.connect mgr ?src dst (fun t ->
    do_request t headers meth request_body endp >>
    read_response channel
  )

let head   mgr ?src ?headers       url = call mgr ?src ?headers `HEAD   None url
let get    mgr ?src ?headers       url = call mgr ?src ?headers `GET    None url
let post   mgr ?src ?headers ?body url = call mgr ?src ?headers `POST   body url
let put    mgr ?src ?headers ?body url = call mgr ?src ?headers `PUT    body url
let delete mgr ?src ?headers       url = call mgr ?src ?headers `DELETE None url
*)
