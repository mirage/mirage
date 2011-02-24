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

module TCPv4 : Nettypes.FLOW with
      type mgr = Manager.t
  and type src = Nettypes.ipv4_src
  and type dst = Nettypes.ipv4_dst

module Pipe : Nettypes.FLOW with
      type mgr = Manager.t
  and type src = Manager.uid
  and type dst = Manager.uid

(* Experimental types to represent run-time flows *)

module TypEq : sig
  type ('a, 'b) t
  val apply : ('a, 'b) t -> 'a -> 'b
end

module rec Typ : sig
  type 'a typ =
  | TCPv4 of ('a, TCPv4.t) TypEq.t
  | Pipe of ('a, Pipe.t) TypEq.t
end

val tcpv4 : TCPv4.t Typ.typ
val pipe : Pipe.t Typ.typ

