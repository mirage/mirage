(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
 * Copyright (C) 2010 Anil Madhavapeddy <anil@recoil.org>
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

type perms = Xsraw.perms
type con = Xsraw.con
type domid = int

type xsh =
{
	con: con;
	debug: string list -> string Lwt.t;
	directory: string -> string list Lwt.t;
	read: string -> string Lwt.t;
	readv: string -> string list -> string list Lwt.t;
	write: string -> string -> unit Lwt.t;
	writev: string -> (string * string) list -> unit Lwt.t;
	mkdir: string -> unit Lwt.t;
	rm: string -> unit Lwt.t;
	getperms: string -> perms Lwt.t;
	setperms: string -> perms -> unit Lwt.t;
	setpermsv: string -> string list -> perms -> unit Lwt.t;
	introduce: domid -> nativeint -> int -> unit Lwt.t;
	release: domid -> unit Lwt.t;
	resume: domid -> unit Lwt.t;
	getdomainpath: domid -> string Lwt.t;
	watch: string -> string -> unit Lwt.t;
	unwatch: string -> string -> unit Lwt.t;
}

let get_operations con = {
	con = con;
	debug = (fun commands -> Xsraw.debug commands con);
	directory = (fun path -> Xsraw.directory 0 path con);
	read = (fun path -> Xsraw.read 0 path con);
	readv = (fun dir vec -> Xsraw.readv 0 dir vec con);
	write = (fun path value -> Xsraw.write 0 path value con);
	writev = (fun dir vec -> Xsraw.writev 0 dir vec con);
	mkdir = (fun path -> Xsraw.mkdir 0 path con);
	rm = (fun path -> Xsraw.rm 0 path con);
	getperms = (fun path -> Xsraw.getperms 0 path con);
	setperms = (fun path perms -> Xsraw.setperms 0 path perms con);
	setpermsv = (fun dir vec perms -> Xsraw.setpermsv 0 dir vec perms con);
	introduce = (fun id mfn port -> Xsraw.introduce id mfn port con);
	release = (fun id -> Xsraw.release id con);
	resume = (fun id -> Xsraw.resume id con);
	getdomainpath = (fun id -> Xsraw.getdomainpath id con);
	watch = (fun path data -> Xsraw.watch path data con);
	unwatch = (fun path data -> Xsraw.unwatch path data con);
}

let transaction xsh = Xst.transaction xsh.con

let has_watchevents xsh = Xsraw.has_watchevents xsh.con
let get_watchevent xsh = Xsraw.get_watchevent xsh.con

let read_watchevent xsh = Xsraw.read_watchevent xsh.con

let make_mmap () = get_operations (Xsraw.open_mmap ())

exception Timeout

(* Should never be thrown, indicates a bug in the read_watchevent_timetout function *)
exception Timeout_with_nonempty_queue

(* Just in case we screw up: poll the callback every couple of seconds rather
   than wait for the whole timeout period *)
let max_blocking_time = 5. (* seconds *)

let read_watchevent_timeout xsh timeout callback =
	let start_time = Mir.gettimeofday () in
	let end_time = start_time +. timeout in

	let left = ref timeout in

	(* Returns true if a watch event in the queue satisfied us *)
	let process_queued_events () = 
		let success = ref false in
                let rec loop () =
		    if Xsraw.has_watchevents xsh.con && not(!success) then (
			success := callback (Xsraw.get_watchevent xsh.con);
                        loop ()
                    ) else
                        !success
                in loop ()
        in
	(* Returns true if a watch event read from the socket satisfied us *)
	let process_incoming_event () = 
		lwt wev = Xsraw.read_watchevent xsh.con in
                return (callback wev)
        in

	let success = ref false in
        let rec loop () =
	    if !left > 0. && not(!success) then begin
		(* NB the 'callback' might call back into Xs functions
		   and as a side-effect, watches might be queued. Hence
		   we must process the queue on every loop iteration *)

		(* First process all queued watch events *)
		if not(!success)
		    then success := process_queued_events ();
		(* Then block for one more watch event *)
		lwt () = 
                    if not(!success) then (
                        lwt s = process_incoming_event () in
                        success := s;
                        return ()
                    ) else
                        return ()
                in
		(* Just in case our callback caused events to be queued
		   and this is our last time round the loop: this prevents
		   us throwing the Timeout_with_nonempty_queue spuriously *)
		if not(!success)
	      	    then success := process_queued_events ();

		(* Update the time left *)
		let current_time = Mir.gettimeofday () in
		left := end_time -. current_time;
                loop ()
            end else 
                return () in
        lwt () = loop () in 
	if not(!success) then begin
		(* Sanity check: it should be impossible for any
		   events to be queued here *)
		if Xsraw.has_watchevents xsh.con then 
                    fail Timeout_with_nonempty_queue
		else 
                    fail Timeout
	end else
            return ()


let monitor_paths xsh l time callback =
	let unwatch () =
		Lwt_list.iter_s (fun (w,v) -> try_lwt xsh.unwatch w v with _ -> return ()) l in
	Lwt_list.iter_s (fun (w,v) -> xsh.watch w v) l >>
	lwt () = try_lwt
		read_watchevent_timeout xsh time callback;
	with exn -> 
                unwatch () >>
                fail exn;
        in
	unwatch ()

