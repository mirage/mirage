(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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

(* UDP channel that uses the UNIX runtime to retrieve fds *)

open Nettypes
open Lwt
open OS

module R = OS.Socket

exception Error of string

module UDPv4 = struct
  type mgr = Manager.t
  type src = ipv4_addr option * int
  type dst = ipv4_addr * int

  type msg = Bitstring.t

  let rec send mgr ?src (dstaddr, dstport) req =
    let (buf,off,len) = req in
    lwt fd = match src with
      |None -> return (Manager.get_udpv4 mgr)
      |Some src -> Manager.get_udpv4_listener mgr src
    in
    let off = off / 8 in
    let len = len / 8 in
    let dst = (ipv4_addr_to_uint32 dstaddr, dstport) in
    match R.udpv4_sendto fd buf off len dst with
    |R.OK len' ->
      if len' != len then
        fail (Error "partial UDP send")
      else
        return ()
    |R.Retry -> 
      Activations.write fd >>
      send mgr (dstaddr, dstport) req
    |R.Err err -> fail (Error err)

  let recv mgr (addr,port) fn =
    lwt lfd = Manager.get_udpv4_listener mgr (addr,port) in
    let buf = String.create 4096 in
    let rec listen () =
      match R.udpv4_recvfrom lfd buf 0 (String.length buf) with
      |R.OK (frm_addr, frm_port, len) ->
        let frm_addr = ipv4_addr_of_uint32 frm_addr in
        let dst = (frm_addr, frm_port) in
        let req = (buf,0,(len * 8)) in
        (* Be careful to catch an exception here, as otherwise
           ignore_result may raise it at some other random point *)
        Lwt.ignore_result (
          try_lwt
            fn dst req
          with exn ->
            return (Printf.printf "EXN: %s\n%!" (Printexc.to_string exn))
        );
        listen ()
      |R.Retry -> Activations.read lfd >> listen ()
      |R.Err _ -> return ()
    in 
    listen ()
end
