(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

open Lwt

type ops =
{
	directory: string -> string list Lwt.t;
	read: string -> string Lwt.t;
	readv: string -> string list -> string list Lwt.t;
	write: string -> string -> unit Lwt.t;
	writev: string -> (string * string) list -> unit Lwt.t;
	mkdir: string -> unit Lwt.t;
	rm: string -> unit Lwt.t;
	getperms: string -> Xsraw.perms Lwt.t;
	setperms: string -> Xsraw.perms -> unit Lwt.t;
	setpermsv: string -> string list -> Xsraw.perms -> unit Lwt.t;
}

let get_operations tid xsh = {
	directory = (fun path -> Xsraw.directory tid path xsh);
	read = (fun path -> Xsraw.read tid path xsh);
	readv = (fun dir vec -> Xsraw.readv tid dir vec xsh);
	write = (fun path value -> Xsraw.write tid path value xsh);
	writev = (fun dir vec -> Xsraw.writev tid dir vec xsh);
	mkdir = (fun path -> Xsraw.mkdir tid path xsh);
	rm = (fun path -> Xsraw.rm tid path xsh);
	getperms = (fun path -> Xsraw.getperms tid path xsh);
	setperms = (fun path perms -> Xsraw.setperms tid path perms xsh);
	setpermsv = (fun dir vec perms -> Xsraw.setpermsv tid dir vec perms xsh);
}

let transaction xsh (f: ops -> 'a) : 'a Lwt.t =
	let result = ref None in
        let rec loop_until_committed () =
	    lwt tid = Xsraw.transaction_start xsh in
	    let t = get_operations tid xsh in
 	    (try_lwt 
	       result := Some (f t);
               return ()
	    with exn ->
		lwt _ = Xsraw.transaction_end tid false xsh in
	        fail exn
            ) >>
            lwt r = Xsraw.transaction_end tid true xsh in
            if r then return () else loop_until_committed ()
        in
        loop_until_committed () >>
	match !result with
	| None        -> fail Xb.Invalid
	| Some result -> return result
