(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2013 Citrix Inc
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

type handle = unit

let init () = ()
let close () = 0

type t = int Generation.t

external stub_bind_unbound_port: int -> int = "stub_evtchn_alloc_unbound"
external stub_bind_interdomain: int -> int -> int = "stub_evtchn_bind_interdomain"
external stub_unmask: int -> unit = "stub_evtchn_unmask"
external stub_notify: int -> unit = "stub_evtchn_notify" "noalloc"
external stub_unbind: int -> unit = "stub_evtchn_unbind"
external stub_virq_dom_exc: unit -> int = "stub_virq_dom_exc"
external stub_bind_virq: int -> int = "stub_bind_virq"

let construct f x = Generation.wrap (f x)
let bind_unbound_port () = construct stub_bind_unbound_port
let bind_interdomain () remote_domid = construct (stub_bind_interdomain remote_domid)

let maybe t f d = Generation.maybe t f d
let unmask () t = maybe t stub_unmask ()
let notify () t = maybe t stub_notify ()
let unbind () t = maybe t stub_unbind ()
let is_valid t = maybe t (fun _ -> true) false

let of_int n = Generation.wrap n
let to_int t = Generation.extract t

let bind_dom_exc_virq () =
  let port = stub_bind_virq (stub_virq_dom_exc ()) in
  construct (fun () -> port) ()

