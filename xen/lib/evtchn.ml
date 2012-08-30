(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

external xenstore_port: unit -> int = "stub_xenstore_evtchn_port"
external console_port: unit -> int = "stub_console_evtchn_port"

external alloc_unbound_port: int -> int = "stub_evtchn_alloc_unbound"
external bind_interdomain: int -> int -> int = "stub_evtchn_bind_interdomain"

external unmask: int -> unit = "stub_evtchn_unmask" 
external notify: int -> unit = "stub_evtchn_notify" "noalloc"

external virq_dom_exc: unit -> int = "stub_virq_dom_exc"

external bind_virq: int -> int = "stub_bind_virq"

module Virq = struct
	type t = Dom_exc

	let bind = function
		| Dom_exc -> bind_virq (virq_dom_exc ())
end
