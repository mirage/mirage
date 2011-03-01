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

  let rec write t view =
    let vlen = OS.Istring.View.length view in
    Printf.printf "Flow.write: %d\n%!" vlen;
    match Tcp.Pcb.write_available t with
    |0 -> (* block for window to open *)
      Tcp.Pcb.write_wait_for t 1 >>
      write t view
    |len when len < vlen -> (* do a short write *)
      let v' = OS.Istring.View.sub view 0 len in
      Tcp.Pcb.write t (`Frag v') >>
      write t (OS.Istring.View.sub view len (vlen - len))
    |len -> (* full write *)
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

type t =
  | TCPv4 of TCPv4.t
  | Shmem of Shmem.t

type mgr = Manager.t

let read = function
  | TCPv4 t -> TCPv4.read t
  | Shmem t -> Shmem.read t

let write = function
  | TCPv4 t -> TCPv4.write t
  | Shmem t -> Shmem.write t

let close = function
  | TCPv4 t -> TCPv4.close t
  | Shmem t -> Shmem.close t

let connect mgr = function
  |`TCPv4 (src, dst, fn) ->
     TCPv4.connect mgr ?src dst (fun t -> fn (TCPv4 t))
  |`Shmem (src, dst, fn) ->
     Shmem.connect mgr ?src dst (fun t -> fn (Shmem t))
  |_ -> fail (Failure "unknown protocol")

let listen mgr = function
  |`TCPv4 (src, fn) ->
     TCPv4.listen mgr src (fun dst t -> fn dst (TCPv4 t))
  |`Shmem (src, fn) ->
     Shmem.listen mgr src (fun dst t -> fn dst (Shmem t))
  |_ -> fail (Failure "unknown protocol")
