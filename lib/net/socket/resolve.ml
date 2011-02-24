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

(* Name resolver that manufactures connections to remote instances *)

open Nettypes
open Lwt

type uid = int
type domain = string

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
  | TCPv4 of ('a, Flow.TCPv4.t) TypEq.t
  | Pipe of ('a, Flow.Pipe.t) TypEq.t
end = Typ

type service = [
 | `HTTP
 | `SMTP
]

let port_of_service = function
 | `HTTP -> 80
 | `SMTP -> 25

type flow = [
 | `TCPv4 of Flow.ipv4_dst
 | `Pipe of uid
]

type datagram = [
 | `UDPv4 of Flow.ipv4_dst
 | `Pipe of uid
]

(* open a direct flow *)
let with_flow name fn =
  match name with
  |`Service (domain, svc) ->
    (* do a DNS SRV lookup *)
    fail (Failure "not implemented")
  |`Host (`TCPv4 dst) ->
    fn (module Flow.TCPv4 : FLOW)
  |`Node (`Uid uid) ->
    fn (module Flow.Pipe : FLOW)

(* open a buffered channel *) 
let with_channel name fn =
  match name with
  |`Service (domain, svc) ->
    (* do a DNS SRV lookup *)
    fail (Failure "not implemented")
  |`Host (`TCPv4 dst) ->
    fn (module Channel.TCPv4 : CHANNEL)
  |`Node (`Uid uid) ->
    fn (module Channel.Pipe : CHANNEL)
 
(* open a datagram connection *)
let with_datagram name fn =
  match name with
  |`Service (domain, svc) ->
    (* do a DNS SRV lookup *)
    fail (Failure "not implemented")
  |`Host (`UDPv4 dst) ->
    fn (module Flow.UDPv4 : DATAGRAM)
