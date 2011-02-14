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

module Unix = struct
  type tcpv4
  type udpv4
  type pipe

  type ipv4 = int32
  type port = int
  type 'a fd

  type 'a resp =
  |OK of 'a
  |Err of string
  |Retry

  external tcpv4_socket: ipv4 -> port -> tcpv4 fd = "caml_tcpv4_socket"
  external tcpv4_connect: ipv4 -> port -> tcpv4 fd resp = "caml_tcpv4_connect"
  external tcpv4_connect_result: tcpv4 fd -> unit resp = "caml_socket_connect_result"
  external tcpv4_bind: ipv4 -> port -> tcpv4 fd resp = "caml_tcpv4_bind"
  external tcpv4_listen: tcpv4 fd -> unit resp = "caml_socket_listen"
  external tcpv4_accept: tcpv4 fd -> (tcpv4 fd * ipv4 * port) resp = "caml_tcpv4_accept"

  external udpv4_socket: unit -> udpv4 fd = "caml_udpv4_socket"
  external udpv4_bind: ipv4 -> port -> udpv4 fd resp = "caml_udpv4_bind"
  external udpv4_recvfrom: udpv4 fd -> OS.Istring.Raw.t -> int -> int -> (ipv4 * port * int) resp = "caml_udpv4_recvfrom"
  external udpv4_sendto: udpv4 fd -> OS.Istring.Raw.t -> int -> int -> (ipv4 * port) -> int resp = "caml_udpv4_sendto"

  external read: 'a fd -> OS.Istring.Raw.t -> int -> int -> int resp = "caml_socket_read"
  external write: 'a fd -> OS.Istring.Raw.t -> int -> int -> int resp = "caml_socket_write"
  external close: 'a fd -> unit = "caml_socket_close"

  external fd : 'a fd -> int = "%identity"

end

type t = {
  udpv4: Unix.udpv4 Unix.fd;
  udpv4_listen_ports: ((ipv4_addr option * int), Unix.udpv4 Unix.fd) Hashtbl.t;
}

(* Enumerate interfaces and manage the protocol threads *)
let create () =
  let udpv4 = Unix.udpv4_socket () in
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
      match Unix.udpv4_bind iaddr port with
      |Unix.OK fd ->
         register_udpv4_listener mgr (addr,port) fd;
         return fd
      |Unix.Err e -> fail (Failure e)
      |Unix.Retry -> assert false
    end
