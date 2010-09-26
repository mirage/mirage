(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>
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
open Lwt

open Http_common
open Http_types

let debug_dump_request path params =
  debug_print ("request path = " ^ path);
  debug_print (
    sprintf"request params = %s"
      (String.concat ";"
        (List.map (fun (h,v) -> String.concat "=" [h;v]) params)))

let auth_sep_RE = Str.regexp_string ":"
let basic_auth_RE = Str.regexp "^Basic +"

type request = {
  r_msg: Http_message.message;
  r_params: (string, string) Hashtbl.t;
  r_get_params: (string * string) list;
  r_post_params: (string * string) list;
  r_meth: meth;
  r_uri: string;
  r_version: version;
  r_path: string;
}
 
let init_request ~clisockaddr ~srvsockaddr finished ic =
  lwt (meth, uri, version) = Http_parser.parse_request_fst_line ic in
  let uri_str = Http_url.to_string uri in
  let path = Http_parser.parse_path uri in
  let query_get_params = Http_parser.parse_query_get_params uri in
  lwt headers = Http_parser.parse_headers ic in
  let headers = List.map (fun (h,v) -> (String.lowercase h, v)) headers in
  lwt body = (if meth = `POST then begin
		let limit = try Some 
                  (Int64.of_string (List.assoc "content-length" headers))
		with Not_found -> None in
		  match limit with 
		    |None -> OS.Flow.read_all ic >|= (fun s -> Lwt.wakeup finished (); [`String s])
		    |Some count -> return [`Inchan (count, ic, finished)]
              end
              else  (* TODO empty body for methods other than POST, is ok? *)
		(Lwt.wakeup finished (); return [`String ""])) in
  lwt query_post_params, body =
    match meth with
      | `POST -> begin
          try
	    let ct = List.assoc "content-type" headers in
	      if ct = "application/x-www-form-urlencoded" then
		(Http_message.string_of_body body) >|= (fun s -> Http_parser.split_query_params s, [`String s])
	      else return ([], body)
	  with Not_found -> return ([], body)
	end
      | _ -> return ([], body)
  in
  let params = query_post_params @ query_get_params in (* prefers POST params *)
  let _ = debug_dump_request path params in
  let msg = Http_message.init ~body ~headers ~version ~clisockaddr ~srvsockaddr in
  let params_tbl =
    let tbl = Hashtbl.create (List.length params) in
      List.iter (fun (n,v) -> Hashtbl.add tbl n v) params;
      tbl in
    return { r_msg=msg; r_params=params_tbl; r_get_params = query_get_params; 
             r_post_params = query_post_params; r_uri=uri_str; r_meth=meth; 
             r_version=version; r_path=path }

let meth r = r.r_meth
let uri r = r.r_uri
let path r = r.r_path
let body r = Http_message.body r.r_msg
let header r ~name = Http_message.header r.r_msg ~name
let client_addr r = Http_message.client_addr r.r_msg

let param ?meth ?default r name =
  try
    (match meth with
     | None -> Hashtbl.find r.r_params name
     | Some `GET -> List.assoc name r.r_get_params
     | Some `POST -> List.assoc name r.r_post_params)
   with Not_found ->
        (match default with
        | None -> raise (Param_not_found name)
        | Some value -> value)

let param_all ?meth r name =
  (match (meth: meth option) with
   | None -> List.rev (Hashtbl.find_all r.r_params name)
   | Some `DELETE
   | Some `HEAD
   | Some `GET -> Http_misc.list_assoc_all name r.r_get_params
   | Some `POST -> Http_misc.list_assoc_all name r.r_post_params)

let params r = r.r_params
let params_get r = r.r_get_params
let params_post r = r.r_post_params

let authorization r = 
  match Http_message.header r.r_msg ~name:"authorization" with
    | [] -> None
    | h :: _ -> 
	let credentials = Base64.decode (Str.replace_first basic_auth_RE "" h) in
	  debug_print ("HTTP Basic auth credentials: " ^ credentials);
	  (match Str.split auth_sep_RE credentials with
	     | [username; password] -> Some (`Basic (username, password))
	     | l -> None)

