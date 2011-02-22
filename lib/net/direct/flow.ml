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
module Pipe = struct
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

module UDPv4 = struct

  type mgr = Manager.t
  type src = ipv4_src
  type dst = ipv4_dst
  type msg = OS.Istring.View.t

  let send mgr ?src (dest_ip, dest_port) msg =
    (* TODO: set src addr here also *)
    let source_port = match src with
      |None -> 37 (* XXX eventually random *)
      |Some (_,p) -> p in
    lwt udp = Manager.udpv4_of_addr mgr None in
    Udp.output udp ~dest_ip (
      let data = `Frag msg in
      Mpl.Udp.t ~source_port ~dest_port ~data
    )

  let recv mgr (src_addr, src_port) fn =
    lwt udp = Manager.udpv4_of_addr mgr src_addr in
    Udp.listen udp src_port
      (fun ip udp ->
        let dst_port = udp#source_port in
        let dst_ip = ipv4_addr_of_uint32 ip#src in
        let dst = dst_ip, dst_port in
        let data = udp#data_sub_view in
        fn dst data
      )
end
