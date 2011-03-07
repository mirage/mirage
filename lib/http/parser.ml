(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>

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
open Lwt

open Common
open Types
open Constants

let bindings_sep, binding_sep, pieces_sep, header_sep =
  Str.(regexp_string "&", regexp_string "=", 
       regexp_string " ", regexp_string ":" )

let header_RE = Str.regexp "([^:]*):(.*)"

let url_decode url = Url.decode url

let split_query_params query =
  let bindings = Str.split bindings_sep query in
  match bindings with
  | [] -> raise (Malformed_query query)
  | bindings ->
      List.map
        (fun binding ->
          match Str.split binding_sep binding with
          | [ ""; b ] -> (* '=b' *)
              raise (Malformed_query_part (binding, query))
          | [ a; b ]  -> (* 'a=b' *) (url_decode a, url_decode b)
          | [ a ]     -> (* 'a=' || 'a' *) (url_decode a, "")
          | _ -> raise (Malformed_query_part (binding, query)))
        bindings

let parse_request_fst_line ic =
  lwt request_line = ic () in
  try_lwt begin
    match Str.split pieces_sep request_line with
    | [ meth_raw; uri_raw; http_version_raw ] ->
        return (method_of_string meth_raw, Url.of_string uri_raw, version_of_string http_version_raw)
    | _ -> fail (Malformed_request request_line)
  end with | Malformed_URL url -> fail (Malformed_request_URI url)

let parse_response_fst_line ic =
  lwt response_line = ic () in
  try_lwt
    (match Str.split pieces_sep response_line with
    | version_raw :: code_raw :: _ ->
       return (version_of_string version_raw,      (* method *)
       status_of_code (int_of_string code_raw))    (* status *)
    | _ ->
   fail (Malformed_response response_line))
  with 
  | Malformed_URL _ | Invalid_code _ | Failure "int_of_string" ->
     fail (Malformed_response response_line)
  | e -> fail e

let parse_path uri =
  match Url.path uri with None -> "/" | Some x -> x

let parse_query_get_params uri =
  try (* act on HTTP encoded URIs *)
    match Url.query uri with None -> [] | Some x -> split_query_params x
  with Not_found -> []

let parse_headers ic =
  (* consume also trailing "^\r\n$" line *)
  let rec parse_headers' headers =
    ic () >>= function
    | "" -> return (List.rev headers)
    | line -> begin
        match Str.(bounded_split (regexp_string ":") line 2) with
        | [header; value] ->
            lwt norm_value =
              try_lwt 
                return (Parser_sanity.normalize_header_value value)
              with _ -> return "" in
            parse_headers' ((String.lowercase header, norm_value) :: headers)
        | _ -> fail (Invalid_header line) 
      end
  in
  parse_headers' []

let parse_request ic =
  lwt (meth, uri, version) = parse_request_fst_line ic in
  let path = parse_path uri in
  let query_get_params = parse_query_get_params uri in
  return (path, query_get_params)

let parse_content_range s =
  try
    let start, fini, total = Scanf.sscanf s "bytes %d-%d/%d" 
      (fun start fini total -> start, fini, total) in
    Some (start, fini, total)
  with Scanf.Scan_failure _ -> None

(* If we see a "Content-Range" header, than we should limit the
   number of bytes we attempt to read *)
let parse_content_range headers = 
  (* assuming header keys were downcased in previous step *)
  if List.mem_assoc "content-length" headers then begin
    try 
      let str = List.assoc "content-length" headers in
      let str = Parser_sanity.normalize_header_value str in
      Some (int_of_string str)
    with _ ->
      None
  end else if List.mem_assoc "content-range" headers then begin
    let range_s = List.assoc "content-range" headers in
    match parse_content_range range_s with
    |Some (start, fini, total) ->
      (* some sanity checking before we act on these values *)
      if fini < total && start <= total && 0 <= start && 0 <= total then (
        let num_bytes_to_read = fini - start + 1 in
        Some num_bytes_to_read
      ) else None
    |None -> None
  end else None    

