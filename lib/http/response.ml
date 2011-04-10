
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

open Types
open Constants
open Common
open Printf
open Lwt
open Net.Nettypes

type response = {
  r_msg: Message.message;
  mutable r_code: int;
  mutable r_reason: string option;
}

let add_basic_headers r =
  Message.add_header r.r_msg ~name:"Date" ~value:(Misc.date_822 ());
  Message.add_header r.r_msg ~name:"Server" ~value:server_string

let init ?(body = [`String ""]) ?(headers = []) ?(version = default_version) ?(status=`Code 200) ?reason () =
  let r_msg = Message.init ~body ~headers ~version in
  let r_code = match status with
  | `Code c -> c
  | #status as s -> code_of_status s in
  let r = { r_msg; r_code; r_reason = reason } in
  add_basic_headers r;
  r

let version_string r = string_of_version (Message.version r.r_msg)

let code r = r.r_code

let set_code r c = 
   ignore (status_of_code c);  (* sanity check on c *)
   r.r_code <- c

let status r = status_of_code (code r)

let set_status r (s: Types.status) = r.r_code <- code_of_status s

let reason r =
  match r.r_reason with
  | None -> Misc.reason_phrase_of_code r.r_code
  | Some r -> r

let set_reason r rs = r.r_reason <- Some rs

let status_line r =
  String.concat " " [version_string r; string_of_int (code r); reason r ]

let is_informational r = Common.is_informational r.r_code
let is_success r = Common.is_success r.r_code
let is_redirection r = Common.is_redirection r.r_code
let is_client_error r = Common.is_client_error r.r_code
let is_server_error r = Common.is_server_error r.r_code
let is_error r = Common.is_error r.r_code

let gh name r =
  match Message.header r.r_msg ~name with
  |[] -> None
  |x :: _ -> Some x

let rh name r = Message.replace_header r.r_msg ~name

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

let serialize_to_channel r =
  let fstLineToString = fstLineToString r in
  Message.serialize_to_channel r.r_msg ~fstLineToString
