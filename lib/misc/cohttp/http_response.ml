
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

open Http_types
open Http_constants
open Http_common
open Printf
open Lwt
open Mlnet.Types

let anyize = function
  | Some addr -> addr
  | None ->
    let addr = match Mlnet.Types.ipv4_addr_of_string "0.0.0.0" with
      | Some x -> x
      | None   -> failwith "anyize" in
    TCP (addr, -1)

type response = {
  r_msg: Http_message.message;
  mutable r_code: int;
  mutable r_reason: string option;
}

let add_basic_headers r =
  Http_message.add_header r.r_msg ~name:"Date" ~value:(Http_misc.date_822 ());
  Http_message.add_header r.r_msg ~name:"Server" ~value:server_string

let init
    ?(body = [`String ""]) ?(headers = []) ?(version = default_version)
    ?(status=`Code 200) ?reason ?clisockaddr ?srvsockaddr ()
    =
  let (clisockaddr, srvsockaddr) = (anyize clisockaddr, anyize srvsockaddr) in
  let r = { r_msg = Http_message.init ~body ~headers ~version ~clisockaddr ~srvsockaddr;
	    r_code = begin match status with
	      | `Code c -> c
	      | #status as s -> code_of_status s
	    end;
	    r_reason = reason } in
  let () = add_basic_headers r in r

let version_string r = string_of_version (Http_message.version r.r_msg)

let code r = r.r_code
let set_code r c = 
   ignore (status_of_code c);  (* sanity check on c *)
   r.r_code <- c
let status r = status_of_code (code r)
let set_status r (s: Http_types.status) = r.r_code <- code_of_status s
let reason r =
   match r.r_reason with
      | None -> Http_misc.reason_phrase_of_code r.r_code
      | Some r -> r
let set_reason r rs = r.r_reason <- Some rs
let status_line r =
      String.concat " "
        [version_string r; string_of_int (code r); reason r ]

let is_informational r = Http_common.is_informational r.r_code
let is_success r = Http_common.is_success r.r_code
let is_redirection r = Http_common.is_redirection r.r_code
let is_client_error r = Http_common.is_client_error r.r_code
let is_server_error r = Http_common.is_server_error r.r_code
let is_error r = Http_common.is_error r.r_code

let gh name r =
  match Http_message.header r.r_msg ~name with [] -> None | x :: _ -> Some x
let rh name r = Http_message.replace_header r.r_msg ~name

let content_type = gh "Content-Type"
let set_content_type = rh "Content-Type"
let content_encoding = gh "Content-Encoding"
let set_content_encoding = rh "Content-Encoding"
let date = gh "Date"
let set_date = rh "Date"
let expires = gh "Expires"
let set_expires = rh "Expires"
let server = gh "Server"
let set_server = rh "Server"

let fstLineToString r =
  sprintf "%s %d %s" (version_string r) (code r) (reason r)

let serialize r outchan write write_from_exactly = 
  let fstLineToString = fstLineToString r in
  Http_message.serialize r.r_msg outchan write write_from_exactly ~fstLineToString

let serialize_to_output_channel r outchan =
  let fstLineToString = fstLineToString r in
  Http_message.serialize_to_output_channel r.r_msg outchan ~fstLineToString

let serialize_to_stream r =
  let fstLineToString = fstLineToString r in
  Http_message.serialize_to_stream r.r_msg ~fstLineToString
