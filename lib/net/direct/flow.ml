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
    let vlen = Bitstring.bitstring_length view / 8 in
    match Tcp.Pcb.write_available t with
    |0 -> (* block for window to open *)
      Tcp.Pcb.write_wait_for t 1 >>
      write t view
    |len when len < vlen -> (* do a short write *)
      let v' = Bitstring.subbitstring view 0 (len * 8) in
      Tcp.Pcb.write t v' >>
      write t (Bitstring.subbitstring view (len*8) ((vlen-len)*8))
    |len -> (* full write *)
      Tcp.Pcb.write t view

  (* For now this is the slow "just concat bitstrings"
     but it should be rewritten to block intelligently based
     on the available write space XXX TODO *)
  let writev t views =
    let view = Bitstring.concat views in
    write t view >>
    return Bitstring.empty_bitstring

  let close t =
    Tcp.Pcb.close t

  let listen mgr src fn =
    let addr, port = src in
    let tcps = Manager.tcpv4_of_addr mgr addr in
    lwt str_lst = Lwt_list.map_s (fun tcp -> return (Tcp.Pcb.listen tcp port)) tcps in
    let rec accept (st, l) =
      lwt c = Lwt_stream.get st in
      match c with 
      | None -> begin
	  return ()
      end
      | Some (fl, th) -> begin
        let _ = fn (Tcp.Pcb.get_dest fl) fl <?> th in
        accept (st, l) 
      end
    in
    let _ = Lwt_list.iter_p accept str_lst in
    let th,_ = Lwt.task () in
    let cancelone (_, l) = Tcp.Pcb.closelistener l in
    Lwt.on_cancel th (fun () -> List.iter cancelone str_lst);
    th

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
  let writev t views = fail (Failure "writev")
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

let writev = function
  | TCPv4 t -> TCPv4.writev t
  | Shmem t -> Shmem.writev t

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


