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
open Printf

open OS.Socket

type id = string
type config = [ `DHCP | `IPv4 of ipv4_addr * ipv4_addr * ipv4_addr list ]

(* Interfaces are a NOOP for the moment, as we depend on them being
   configured externally *)
type interface = unit
let configure () config = return ()

type t = {
  domain: [`domain] fd;
  peers: (peer_uid, [`domain] fd) Hashtbl.t;
  udpv4: [`udpv4] fd;
  udpv4_listen_ports: ((ipv4_addr option * int), [`udpv4] fd) Hashtbl.t;
}

let get_intf intf = 
   ""

(* Get a set of all the local peers *)
let local_peers t = domain_list ()

(* Get our local UID *)
let local_uid t = domain_uid ()

let intercept t fn =
  Printf.printf "Intercept not implemented yet for socket mode "

(* Connect to a peer and return a control socket to it *)
let connect_to_peer t uid =
 if Hashtbl.mem t.peers uid then
   return (Some (Hashtbl.find t.peers uid))
 else begin
   try_lwt
     lwt fd = iobind domain_connect uid in
     let our_uid = string_of_int (domain_uid ()) in
     fdbind OS.Activations.write connect_result fd >>
     lwt () = fdbind OS.Activations.write (fun fd -> domain_write fd our_uid) fd in
     Hashtbl.add t.peers uid fd;
     return (Some fd)
   with exn ->
     return None
  end

(* Loop and listen for incoming domain socket connections from peers *)
let listen_to_peers t fn =
  let fd = t.domain in
  let rec accept_t () =
    lwt lfd = fdbind OS.Activations.read domain_accept fd in
    (* Read the peer uid, uint32_t *)
    lwt uid_s = fdbind OS.Activations.read domain_read lfd in
    let uid = int_of_string uid_s in
    printf "Connection from peer %d\n%!" uid;
    (* Loop and listen for incoming pipe FDs *)
    let rec get_pipe () = 
      lwt wr_pipe = fdbind OS.Activations.read domain_recv_pipe lfd in
      lwt rd_pipe = fdbind OS.Activations.read domain_recv_pipe lfd in
      fn uid (rd_pipe, wr_pipe)
    in accept_t () <&> (get_pipe ())
  in accept_t ()

(* Exchange a pipe pair with a peer *)
let rec connect t uid fn =
  (* First get the domain socket connection to the peer *)
  connect_to_peer t uid >>= function
  |None ->
    printf "Manager: no control socket to %d\n%!" uid;
    fail (Error "connect")
  |Some fd -> begin
    (* Generate a pipe pair for bi-direction comms *)
    lwt rd_pipe, wr_pipe = iobind pipe () in
    lwt rd_pipe', wr_pipe' = iobind pipe () in
    iobind (domain_send_pipe fd) wr_pipe >>
    iobind (domain_send_pipe fd) rd_pipe' >>
    fn (rd_pipe, wr_pipe') 
  end 
 
(* Enumerate interfaces and manage the protocol threads *)
let create listener =
  let udpv4 = udpv4_socket () in
  let udpv4_listen_ports = Hashtbl.create 7 in
  lwt domain = iobind domain_bind (domain_uid ()) in
  (* TODO: cleanup the domain socket atexit *)
  (* List all other domains at startup *)
  (*
  let other_uids = OS.Socket.domain_list () in
  let our_uid = OS.Socket.domain_uid () in
  *)
  let peers = Hashtbl.create 7 in
  let t = { udpv4; udpv4_listen_ports; domain; peers } in
  listener t () ""

let get_udpv4 t =
  t.udpv4

(* TODO: sort out cleanup of fds *)
let register_udpv4_listener mgr src fd =
  Hashtbl.add mgr.udpv4_listen_ports src fd

let get_udpv4_listener mgr (addr,port) =
  try
    return (Hashtbl.find mgr.udpv4_listen_ports (addr,port))
  with Not_found -> begin
    let iaddr = match addr with None -> 0l |Some a -> ipv4_addr_to_uint32 a in
    lwt fd = iobind (udpv4_bind iaddr) port in
    register_udpv4_listener mgr (addr,port) fd;
    return fd
  end
