(*pp camlp4o -I `ocamlfind query lwt.syntax` pa_lwt.cmo *)

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
module OS = Unix
module IO = Unix.IO

open Http_common
open Http_constants
open Http_types
open Printf
open Lwt

  (* remove all bindings of 'name' from hashtbl 'tbl' *)
let rec hashtbl_remove_all tbl name =
  if not (Hashtbl.mem tbl name) then
    raise (Header_not_found name);
  Hashtbl.remove tbl name;
  if Hashtbl.mem tbl name then hashtbl_remove_all tbl name

type contents =
    [ `Buffer of Buffer.t
    | `String of string
    | `Inchan of int64 * IO.input_channel * unit Lwt.u
    ]

type message = {
  mutable m_contents : contents list;
  m_headers : (string, string) Hashtbl.t;
  m_version : version;
  m_cliaddr : string;
  m_cliport : int;
  m_srvaddr : string;
  m_srvport : int;
} 

let body msg = List.rev msg.m_contents
let body_size cl =
  let (+) = Int64.add in
    List.fold_left (fun a c -> match c with
		      | `String s -> a + (Int64.of_int (String.length s))
		      | `Buffer b -> a + (Int64.of_int (Buffer.length b))
		      | `Inchan (i, _, _) -> a + i) Int64.zero cl
let string_of_body cl =
  (* TODO: What if the body is larger than 1GB? *)
  let buf = String.create (Int64.to_int (body_size cl)) in
    (List.fold_left (fun pos c -> match c with
		       | `String s ->
			   lwt pos = pos in
                           let len = String.length s in
			   let () = String.blit s 0 buf pos len in
			     return (pos + len)
                       | `Buffer b ->
			   lwt pos = pos in
                           let len = Buffer.length b in
			   let str = Buffer.contents b in
			   let () = String.blit str 0 buf pos len in
			     return (pos + len)
	               | `Inchan (il, ic, finished) ->
			   lwt pos = pos in
                           let il = Int64.to_int il in
                             (IO.read_into_exactly ic buf pos il) >>
			       (Lwt.wakeup finished (); return (pos + il))
                    ) (return 0) cl) >>= (fun _ -> return buf)
let set_body msg contents = msg.m_contents <- [contents]
let add_body msg contents = msg.m_contents <- (contents :: msg.m_contents)
let add_header msg ~name ~value =
  let name = String.lowercase name in
  Http_parser_sanity.heal_header (name, value);
  Hashtbl.add msg.m_headers name value
let add_headers msg =
  List.iter (fun (name, value) -> add_header msg ~name ~value)
let replace_header msg ~name ~value =
  let name = String.lowercase name in
  Http_parser_sanity.heal_header (name, value);
  Hashtbl.replace msg.m_headers name value
let replace_headers msg =
  List.iter (fun (name, value) -> replace_header msg ~name ~value)
let remove_header msg ~name =
  let name = String.lowercase name in
  hashtbl_remove_all msg.m_headers name
let has_header msg ~name =
  Hashtbl.mem msg.m_headers name
let header msg ~name =
  let name = String.lowercase name in
  let compact = String.concat ", " in
    (* TODO: Just these old headers or all of HTTP 1.0? *)
  let no_compact = ["set-cookie"] in
    if has_header msg ~name then
      let hl = List.rev (Hashtbl.find_all msg.m_headers name) in
	if List.mem name no_compact then hl
	else [compact hl]
    else []
let headers msg =
  let hset = Hashtbl.create 11 in
  let () = Hashtbl.iter (fun name _ -> Hashtbl.replace hset name ()) msg.m_headers in
    Hashtbl.fold (fun name _ headers -> 
		    List.rev_append
		      (List.map (fun h -> (name, h)) (header msg ~name))
		      headers
		 ) hset []
    
let client_addr msg = msg.m_cliaddr
let server_addr msg = msg.m_srvaddr
let client_port msg = msg.m_cliport
let server_port msg = msg.m_srvport

let version msg = msg.m_version

let init ~body ~headers ~version ~clisockaddr ~srvsockaddr =
  let ((cliaddr, cliport), (srvaddr, srvport)) =
    (Http_misc.explode_sockaddr clisockaddr,
     Http_misc.explode_sockaddr srvsockaddr) in
  let msg = { m_contents = body;
	      m_headers = Hashtbl.create 11;
	      m_version = version;
	      m_cliaddr = cliaddr;
	      m_cliport = cliport;
	      m_srvaddr = srvaddr;
	      m_srvport = srvport;
	    } in
    add_headers msg headers;
    msg
      
let relay ic oc write_from_exactly m =
  let bufsize = 4096 in (* blksz *)
  let buffer = String.create bufsize in
  let rec aux m =
    lwt len = m >> (IO.read_into ic buffer 0 bufsize) in
      if len = 0 then Lwt.return ()
      else aux (write_from_exactly oc buffer 0 len)
  in aux m

let serialize msg outchan write write_from_exactly ~fstLineToString =
  let body = body msg in
  let bodylen = body_size body
  in (write outchan (fstLineToString ^ crlf)) >>
       (List.fold_left
	  (fun m (h,v) ->
	     m >> write outchan (h ^ ": " ^ v ^ crlf))
	  (Lwt.return ())
	  (headers msg)) >>
       (if bodylen != Int64.zero then
	  write outchan (sprintf "Content-Length: %Ld\r\n\r\n" bodylen)
	else return ()) >>
       (List.fold_left
	  (fun m c -> match c with
	     | `String s -> m >> (write outchan s)
	     | `Buffer b -> m >> (write outchan (Buffer.contents b))
	     | `Inchan (_, ic, finished) -> relay ic outchan write_from_exactly m >> (Lwt.wakeup finished (); Lwt.return ()))
	  (Lwt.return ())
	  body)

let serialize_to_output_channel msg outchan ~fstLineToString =
  serialize msg outchan IO.write IO.write_from_exactly ~fstLineToString

let serialize_to_stream msg ~fstLineToString =
  let stream, push = Lwt_stream.create () in
  Lwt.ignore_result
    (serialize
       msg
       ()
       (fun () s -> push (Some s); Lwt.return ())
       (fun () buf off len -> push (Some (String.sub buf off len)); Lwt.return ())
       ~fstLineToString >> (push None; Lwt.return ()));
  stream
