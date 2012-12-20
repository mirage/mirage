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

external xenstore_start_page: unit -> Io_page.t = "caml_xenstore_start_page"

module Client = Xs_client.Client(struct

	type t = {
		page: Cstruct.t;
		evtchn: int;
	}
	(* An inter-domain client is always via a shared memory page
	    and an event channel. *)

	let t = ref None
	(* Unfortunately there is only one connection and it cannot
	    be closed or reopened. *)

	exception Already_connected

	exception Cannot_destroy

	let create () =
		match !t with
		| Some _ ->
			Console.log "ERROR: Already connected to xenstore: cannot reconnect";
			fail Already_connected
		| None ->
			let page = Io_page.to_cstruct (xenstore_start_page ()) in
			Xenstore_ring.Ring.init page;
			let evtchn = Evtchn.xenstore_port () in
			return { page; evtchn }

	let destroy t =
		Console.log "ERROR: It's not possible to destroy the default xenstore connection";
		fail Cannot_destroy

	(* XXX: unify with ocaml-xenstore-xen/xen/lib/xs_transport_domain *)
	let rec read t buf ofs len =
		let n = Xenstore_ring.Ring.Front.unsafe_read t.page buf ofs len in
		if n = 0 then begin
			lwt () = Activations.wait t.evtchn in
			read t buf ofs len
		end else begin
			Evtchn.notify t.evtchn;
			return n
		end

	(* XXX: unify with ocaml-xenstore-xen/xen/lib/xs_transport_domain *)
	let rec write t buf ofs len =
		let n = Xenstore_ring.Ring.Front.unsafe_write t.page buf ofs len in
		if n > 0 then Evtchn.notify t.evtchn;
		if n < len then begin
			lwt () = Activations.wait t.evtchn in
			write t buf (ofs + n) (len - n)
		end else return ()
end)

include Client

let client = make ()

let immediate f =
	lwt client = client in
	with_xs client f

let transaction f =
	lwt client = client in
	with_xst client f

let wait f =
	lwt client = client in
	wait client f
