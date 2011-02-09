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

(* The manager process binds application ports to interfaces, and
   will eventually deal with load balancing and route determination
   (e.g. if a remote target is on the same host, swap to shared memory *)

open Lwt
open Nettypes

exception Error of string

type fd = int
type t = {
  udpv4: fd;
  udpv4_listen_ports: ((ipv4_addr option * int), fd) Hashtbl.t;
}

(* TODO: abstract type for UDP socket *)
external unix_udp_socket_ipv4: unit -> int = "caml_udp_socket_ipv4"
external unix_bind_ipv4: (int32 * int) -> int resp = "caml_udp_bind_ipv4"

(* Enumerate interfaces and manage the protocol threads *)
let create () =
  let udpv4 = unix_udp_socket_ipv4 () in
  let udpv4_listen_ports = Hashtbl.create 7 in
  return { udpv4; udpv4_listen_ports }
  
let destroy t =
  ()

let get_udpv4 t =
  t.udpv4

(* TODO: sort out cleanup of fds *)
let register_udpv4_listener mgr src fd =
  Hashtbl.add mgr.udpv4_listen_ports src fd

let get_udpv4_listener mgr (addr,port) =
  try
    return (Hashtbl.find mgr.udpv4_listen_ports (addr,port))
  with
    Not_found -> begin
      let iaddr = match addr with None -> 0l |Some a -> ipv4_addr_to_uint32 a in
      match unix_bind_ipv4 (iaddr, port) with
      |OK fd ->
         register_udpv4_listener mgr (addr,port) fd;
         return fd
      |Err e -> fail (Failure e)
      |Retry -> assert false
    end
