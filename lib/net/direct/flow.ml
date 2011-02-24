(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

open Lwt
open Nettypes

type ipv4_src = ipv4_addr option * int   (* optional IP address * port *)
type ipv4_dst = ipv4_addr * int          (* specific IP address * port *)

module TCPv4 = struct

  type t = Tcp.Pcb.pcb
  type mgr = Manager.t
  type src = ipv4_src
  type dst = ipv4_dst

  let read t =
    Tcp.Pcb.read t

  let write t view =
    let len = Int32.of_int (OS.Istring.View.length view) in
    Tcp.Pcb.write_wait_for t len >>
    Tcp.Pcb.write t (`Frag view)

  let close t =
    Tcp.Pcb.close t

  let listen mgr src fn =
    let addr, port = src in
    lwt tcp = Manager.tcpv4_of_addr mgr addr in
    Tcp.Pcb.listen tcp port fn

  let connect mgr ?src dst fn =
    fail (Failure "Not_implemented")

end

(* Shared mem communication across VMs, not yet implemented *)
module Shmem = struct
  type t = unit
  type mgr = Manager.t
  type src = int
  type dst = int

  let read t = fail (Failure "read")
  let write t view = fail (Failure "write")
  let close t = fail (Failure "close")

  let listen mgr src fn = fail (Failure "listen")
  let connect mgr ?src dst fn = fail (Failure "connect")

end

module TypEq : sig
  type ('a, 'b) t
  val apply: ('a, 'b) t -> 'a -> 'b
  val refl: ('a, 'a) t
  val sym: ('a, 'b) t -> ('b, 'a) t
end = struct
  type ('a, 'b) t = ('a -> 'b) * ('b -> 'a)
  let refl = (fun x -> x), (fun x -> x)
  let apply (f, _) x = f x
  let sym (f, g) = (g, f)
end

module rec Typ : sig
  type 'a typ =
  | TCPv4 of ('a, TCPv4.t) TypEq.t
  | Shmem of ('a, Shmem.t) TypEq.t
end = Typ

let tcpv4 = Typ.TCPv4 TypEq.refl
let shmem = Typ.Shmem TypEq.refl
